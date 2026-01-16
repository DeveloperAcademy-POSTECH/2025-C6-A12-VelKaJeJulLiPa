/**
 * =============================================================================
 * ⚠️ Notice
 * -----------------------------------------------------------------------------
 * 이 파일은 Cloud Functions에 배포하는 코드입니다.
 * 기능 수정 또는 로직 변경 시 반드시 아래 절차를 준수해주세요.
 *
 * 1) 코드 변경 후 반드시 저장 (File > Save)
 * 2) 로컬 환경에서 빌드 및 배포:
 *       ```bash
 *       npm run deploy
 *       ```
 *    - 해당 스크립트는 TypeScript 빌드 후 Cloud Functions 전체를 배포합니다.
 *    - 배포에는 다소 시간이 소요될 수 있습니다. (현재는 5분 내외)
 *
 * 3) 배포 전 확인사항:
 *    - logger 활용한 적절한 로깅 처리가 잘 되어있는지 확인 
 *    - Firestore 컬렉션 및 필드 네이밍이 실제와 일치하는지 확인
 *    - Infinite loop 가능성이 있는 Firestore 트리거 코드를 반드시 검토
 *    - region 설정 및 maxInstances 설정 변경 시 팀원과 사전 공유 필수
 *
 * 4) 주의:
 *    - 테스트 환경과 운영 환경의 설정(firebase config)이 다를 수 있습니다.
 *    - IAM 권한 또는 Firestore 보안 규칙 변경이 필요한 경우 팀 리드에게 확인 요청
 *
 * ※ 배포 실패 시:
 *     Firebase Console > Functions > CLI 출력 로그를 통해 원인을 확인하세요.
 * 
 * * 운영 로그 확인:
 *     Firebase Console > Functions > Google Cloud Console > Logs Exmplorer 애서 로그를 확인할 수 있습니다.
 *  
 * -----------------------------------------------------------------------------
 * 담당자: Paidion(김준구)
 * 최근 수정: 2025-11-14
 * =============================================================================
 */

import * as admin from "firebase-admin";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { setGlobalOptions } from "firebase-functions";
import * as logger from "firebase-functions/logger";
import { defineString } from "firebase-functions/params";
import { josa } from "es-hangul";
import { v4 as uuidv4 } from "uuid";
import * as nodemailer from "nodemailer";
import * as jwt from "jsonwebtoken";

// 환경 변수 정의
const gmailUser = defineString("GMAIL_USER");
const gmailPassword = defineString("GMAIL_PASSWORD");

// Apple Sign-In Migration 환경 변수 (Secret Manager에서 자동 주입됨)
// defineString 대신 process.env로 접근 (함수 내에서 secrets 선언 시 자동 주입)

admin.initializeApp();
setGlobalOptions({ region: "asia-northeast3", maxInstances: 10 });

const db = admin.firestore();
const fcm = admin.messaging();

const URL_SCHEME = "dancemachine";

/**
 * 특정 수신자(receiverId)가 발신자(senderId)를 차단했는지 확인
 */
async function isUserBlockedBy(receiverId: string, senderId: string): Promise<boolean> {
  const blockDoc = await db
    .collection("users")
    .doc(receiverId)
    .collection("blocks")
    .doc(senderId)
    .get();
  return blockDoc.exists;
}

/**
 * 사용자별로 푸시 알림 전송 (사용자별 badge 포함)
 *
 * @param receivers 사용자 ID 배열
 * @param title 알림 제목
 * @param body 알림 본문
 * @param extra 추가 데이터 (video_id, video_title, video_url, notification_id, teamspace_id)
 */
async function sendPushNotificationsWithBadge(
  receivers: string[],
  title: string,
  body: string,
  extra: { video_id: string; video_title: string; video_url: string, notification_id: string, teamspace_id: string }
) {
  if (receivers.length === 0) {
    logger.error("sendPushNotificationsWithBadge: no receivers", { receivers });
    return;
  }

  const oneMonthAgo = admin.firestore.Timestamp.fromDate(
    new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)
  );

  // 사용자별 badge 카운트 계산
  const badgeCounts = await Promise.all(
    receivers.map(async (uid) => {
      // user_notification 서브컬렉션에서 한 달 전부터, is_read == false 인 문서 수 계산
      const snapshot = await db
        .collection("users").doc(uid)
        .collection("user_notification")
        .where("created_at", ">=", oneMonthAgo)
        .where("is_read", "==", false)
        .get();

      return { uid, unreadCount: snapshot.size };
    })
  );

  // 사용자별 토큰 + 메시지 전송
  await Promise.all(
    badgeCounts.map(async ({ uid, unreadCount }) => {
      const userDoc = await db.collection("users").doc(uid).get();
      if (!userDoc.exists) {
        logger.error("User doc not found for push", { uid });
        return;
      }
      const token = userDoc.get("fcm_token");
      
      // 토큰 유효성 확인
      // 1. 로그아웃 사용자 fcm_token: 빈 문자열("")
      // 2. 유효하지 않은 토큰 (토큰 타입 / 토큰 길이 / FCM 토큰 발행 및 갱신 문제)
      if (!token) {
        logger.info("Skipping push notification for signed out user", { uid })
        return;
      } else if (typeof token !== "string" || token.length === 0 || token == "Unknown") {
        logger.warn("FCM token is missing", { uid });
        return;
      }

      // 딥링크 생성
      const encodedTitle = encodeURIComponent(extra.video_title);
      const encodedUrl = encodeURIComponent(extra.video_url);
      const encodedTeamspaceId = encodeURIComponent(extra.teamspace_id);
      let deeplink = `${URL_SCHEME}://video/view?videoId=${extra.video_id}&videoTitle=${encodedTitle}&videoURL=${encodedUrl}&teamspaceId=${encodedTeamspaceId}`;
      

      const message: admin.messaging.Message = {
        token,
        notification: {
          title,
          body,
        },
        apns: {
          payload: {
            aps: {
              alert: { title, body },
              badge: unreadCount,
              sound: "default",
            },
          },
        },
        data: {
          deeplink,
          notificationId: extra.notification_id,
        },
      };

      try {
        await fcm.send(message);
        logger.info("Push sent", { uid, unreadCount, token });
      } catch (error) {
        logger.error("Error sending push", { uid, unreadCount, token, error });
      }
    })
  );
}

/**
 * feedback 문서 생성 시 알림 처리 트리거
 */
export const onFeedbackCreated = onDocumentCreated("feedback/{feedbackId}", async (event) => {
  const snap = event.data;
  if (!snap) {
    logger.error("[Feedback] - No snapshot", { eventId: event.id });
    return;
  }
  const feedback = snap.data();

  const { feedback_id, author_id, tagged_user_ids, content, video_id, teamspace_id } = feedback;

  if (!tagged_user_ids || tagged_user_ids.length === 0) {
    logger.info("[Feedback] - No tagged users", { feedback_id });
    return;
  }

  const validTaggedUsers: string[] = [];
  await Promise.all(
    tagged_user_ids.map(async (receiverId: string) => {
      const blocked = await isUserBlockedBy(receiverId, author_id);
      if (!blocked) validTaggedUsers.push(receiverId);
    })
  );

  if (validTaggedUsers.length === 0) {
    logger.error("[Feedback] - No valid tagged users", { feedback_id });
    return;
  }

  logger.debug("[Feedback] - Valid tagged users", { validTaggedUsers });

  const notification_id = uuidv4().toUpperCase();

  // notification 문서 생성
  await db.collection("notification").doc(notification_id).set({
    notification_id,
    sender_id: author_id,
    receiver_ids: validTaggedUsers,
    feedback_id,
    created_at: admin.firestore.FieldValue.serverTimestamp(),
    video_id,
    teamspace_id,
    content,
  });
  logger.info("[Feedback] - Notification doc created", { feedback_id, validTaggedUsers, notification_id });

  // user_notification 생성
  await Promise.all(
    validTaggedUsers.map(async (uid) => {
      await db
        .collection("users").doc(uid)
        .collection("user_notification")
        .doc(notification_id)
        .set({
          notification_id,
          teamspace_id,
          created_at: admin.firestore.FieldValue.serverTimestamp(),
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
          is_read: false,
        });
    })
  );
  logger.info("[Feedback] - user_notification documents created", { validTaggedUsers });

  // 푸시 전송
  const authorDoc = await db.collection("users").doc(author_id).get();
  const name = authorDoc.exists ? authorDoc.get("name") : null;
  if (!name) {
    logger.error("[Feedback] - Author name not found", { author_id });
    return;
  }
  const videoDoc = await db.collection("video").doc(video_id).get();
  const video_title = videoDoc.exists ? videoDoc.get("video_title") : null;
  const video_url = videoDoc.exists ? videoDoc.get("video_url") : null;
  if (!video_title || !video_url) {
    logger.error("[Feedback] - Video info not found", { video_id });
    return;
  }

  const title = `${josa(name, "이/가")} 피드백을 남겼어요`;
  const body = content;
  const extra = { video_id, video_title, video_url, notification_id, teamspace_id };

  await sendPushNotificationsWithBadge(validTaggedUsers, title, body, extra);
  logger.info("[Feedback] - Push notification process completed", { validTaggedUsers, title, body, extra });
});

/**
 * reply 문서 생성 시 알림 처리 트리거
 */
export const onReplyCreated = onDocumentCreated("feedback/{feedbackId}/reply/{replyId}", async (event) => {
  const snap = event.data;
  if (!snap) {
    logger.error("[Reply] - No snapshot", { eventId: event.id });
    return;
  }
  const reply = snap.data();
  const { reply_id, feedback_id, author_id, tagged_user_ids, content } = reply;

  const feedbackDoc = await db.collection("feedback").doc(feedback_id).get();
  const feedbackAuthorId = feedbackDoc.exists ? feedbackDoc.get("author_id") : null;
  const teamspace_id = feedbackDoc.exists ? feedbackDoc.get("teamspace_id") : null;
  const video_id = feedbackDoc.exists ? feedbackDoc.get("video_id") : null;
  if (!feedbackAuthorId || !teamspace_id || !video_id) {
    logger.error("[Reply] - Feedback document is incomplete", { feedback_id, feedbackAuthorId, teamspace_id, video_id });
    return;
  }

  const validTaggedUsers: string[] = [];
  await Promise.all(
    tagged_user_ids.map(async (receiverId: string) => {
      const blocked = await isUserBlockedBy(receiverId, author_id);
      if (!blocked) validTaggedUsers.push(receiverId);
    })
  );
  logger.debug("[Reply] - Valid tagged users", { validTaggedUsers });

  // 피드백 작성자 == 댓글 작성자 && 태그된 사용자 없음 → 알림 없음
  if (feedbackAuthorId === author_id && validTaggedUsers.length === 0) {
    logger.info("[Reply] - Reply author is same as feedback author and no tagged users — skipping notification", { reply_id });
    return;
  }

  let validReceivers: string[];
  if (feedbackAuthorId === author_id) {
    validReceivers = validTaggedUsers;
  } else {
    validReceivers =
      validTaggedUsers.length === 0
        ? [feedbackAuthorId]
        : [feedbackAuthorId, ...validTaggedUsers];
  }
  // 작성자 본인은 알림 대상에서 제외
  validReceivers = validReceivers.filter((uid) => uid !== author_id);

  if (validReceivers.length === 0) {
    logger.info("[Reply] - No valid receivers", { reply_id });
    return;
  }

  const notification_id = uuidv4().toUpperCase();

  await db.collection("notification").doc(notification_id).set({
    notification_id,
    sender_id: author_id,
    receiver_ids: validReceivers,
    feedback_id,
    reply_id,
    created_at: admin.firestore.FieldValue.serverTimestamp(),
    video_id,
    teamspace_id,
    content,
  });
  logger.info("[Reply] - Notification document created", { reply_id, validReceivers, notification_id });

  // user_notification 생성
  await Promise.all(
    validReceivers.map(async (uid) => {
      await db
        .collection("users").doc(uid)
        .collection("user_notification")
        .doc(notification_id)
        .set({
          notification_id,
          teamspace_id,
          created_at: admin.firestore.FieldValue.serverTimestamp(),
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
          is_read: false,
        });
    })
  );
  logger.info("[Reply] - user_notification documents created", { validReceivers });

  const authorDoc = await db.collection("users").doc(author_id).get();
  const name = authorDoc.exists ? authorDoc.get("name") : null;
  if (!name) {
    logger.error("[Reply] - Reply author name not found", { author_id });
    return;
  }
  const videoDoc = await db.collection("video").doc(video_id).get();
  const video_title = videoDoc.exists ? videoDoc.get("video_title") : null;
  const video_url = videoDoc.exists ? videoDoc.get("video_url") : null;
  if (!video_title || !video_url) {
    logger.error("[Reply] - Video info not found", { video_id });
    return;
  }

  const title = `${josa(name, "이/가")} 댓글을 남겼어요`;
  const body = content;
  const extra = { video_id, video_title, video_url, notification_id, teamspace_id };

  await sendPushNotificationsWithBadge(validReceivers, title, body, extra);
  logger.info("[Reply] - Push notification process completed", { validReceivers, title, body, extra });
});

/**
 * 문의하기 이메일 전송 트리거
 * inquiries 컬렉션에 새 문서가 생성되면 자동으로 이메일 발송
 */
export const sendInquiryEmail = onDocumentCreated("inquiries/{inquiryId}", async (event) => {
  const snap = event.data;
  if (!snap) {
    logger.error("[Inquiry] - No snapshot", { eventId: event.id });
    return;
  }

  const inquiry = snap.data();
  const { userId, content, createdAt } = inquiry;

  // 사용자 정보 가져오기
  let userName = "Unknown";
  let userEmail = "Unknown";
  try {
    const userDoc = await db.collection("users").doc(userId).get();
    if (userDoc.exists) {
      userName = userDoc.get("name") || "Unknown";
      userEmail = userDoc.get("email") || "Unknown";
    }
  } catch (error) {
    logger.error("[Inquiry] - Error fetching user info", { userId, error });
  }

  // Nodemailer 설정
  const transporter = nodemailer.createTransport({
    service: "gmail",
    auth: {
      user: gmailUser.value(),
      pass: gmailPassword.value(),
    },
  });

  // 이메일 내용
  const mailOptions = {
    from: gmailUser.value(),
    to: gmailUser.value(), // 같은 주소로 받기
    subject: `[DirAct 문의] ${userName}님의 문의`,
    html: `
      <h2>DirAct 앱 문의</h2>
      <p><strong>작성자:</strong> ${userName} (${userEmail})</p>
      <p><strong>사용자 ID:</strong> ${userId}</p>
      <p><strong>작성 시간:</strong> ${createdAt ? new Date(createdAt._seconds * 1000).toLocaleString("ko-KR") : "Unknown"}</p>
      <hr>
      <h3>문의 내용:</h3>
      <p>${content}</p>
    `,
  };

  // 이메일 전송
  try {
    await transporter.sendMail(mailOptions);
    logger.info("[Inquiry] - Email sent successfully", { userId, userName, userEmail });
  } catch (error) {
    logger.error("[Inquiry] - Error sending email", { userId, error });
  }
});

/**
 * =============================================================================
 * Apple Sign-In Transfer Identifier Migration
 * =============================================================================
 */

/**
 * Apple용 JWT 생성
 * Apple Migration API 인증에 필요한 client secret 토큰 생성
 */
function generateAppleClientSecret(): string {
  const now = Math.floor(Date.now() / 1000);

  const payload = {
    iss: process.env.APPLE_TEAM_ID,
    iat: now,
    exp: now + 86400 * 180, // 180일 (최대값)
    aud: "https://appleid.apple.com",
    sub: "com.dirAct", // Bundle ID
  };

  const privateKey = (process.env.APPLE_PRIVATE_KEY || "").replace(/\\n/g, "\n"); // 개행 처리

  const token = jwt.sign(payload, privateKey, {
    algorithm: "ES256",
    keyid: process.env.APPLE_KEY_ID,
  });

  return token;
}

/**
 * Apple Migration API 호출
 * transfer_sub를 사용하여 기존 사용자 식별자 조회
 *
 * @param transferSub - Apple Sign-In에서 제공하는 transfer_sub 값
 * @returns 기존 사용자 식별자 (sub)
 */
async function getTransferredAppleUserId(transferSub: string): Promise<string | null> {
  try {
    const clientSecret = generateAppleClientSecret();

    const response = await fetch("https://appleid.apple.com/auth/usermigrationinfo", {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: new URLSearchParams({
        client_id: "com.dirAct", // Bundle ID
        client_secret: clientSecret,
        transfer_sub: transferSub,
      }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      logger.error("[Apple Migration] API error", {
        status: response.status,
        statusText: response.statusText,
        error: errorText
      });
      return null;
    }

    const data = await response.json();
    logger.info("[Apple Migration] API success", { data });

    // Apple API는 { sub: "기존 식별자" } 형태로 반환
    return data.sub || null;
  } catch (error) {
    logger.error("[Apple Migration] API call failed", { error, transferSub });
    return null;
  }
}

/**
 * 사용자 마이그레이션 HTTPS Callable Function
 * iOS 앱에서 호출하여 transfer_sub로 기존 계정 찾고 병합
 *
 * @param data.transferSub - Apple Sign-In의 transfer_sub
 * @param data.currentUid - 현재 Firebase UID
 * @param data.email - 사용자 이메일 (옵션)
 * @param data.name - 사용자 이름 (옵션)
 */
export const migrateAppleUser = onCall(
  {
    secrets: ["APPLE_TEAM_ID", "APPLE_KEY_ID", "APPLE_PRIVATE_KEY"],
  },
  async (request) => {
    const { transferSub, currentUid, email, name } = request.data;

    logger.info("[Migration] 시작", { transferSub, currentUid, email, name });

    // 입력 검증
    if (!transferSub || typeof transferSub !== "string") {
      throw new HttpsError("invalid-argument", "transferSub is required");
    }
    if (!currentUid || typeof currentUid !== "string") {
      throw new HttpsError("invalid-argument", "currentUid is required");
    }

    try {
      // 1. Apple Migration API로 기존 식별자 조회
      const originalSub = await getTransferredAppleUserId(transferSub);

      if (!originalSub) {
        logger.warn("[Migration] 기존 식별자를 찾을 수 없음", { transferSub });
        return {
          success: false,
          message: "No original user found",
          migratedFrom: null,
        };
      }

      logger.info("[Migration] 기존 식별자 찾음", { originalSub });

      // 2. Firebase Auth에서 기존 사용자 찾기 (UID가 originalSub인 사용자)
      try {
        await admin.auth().getUser(originalSub);
        logger.info("[Migration] Firebase Auth에서 기존 유저 찾음", { uid: originalSub });
      } catch (error) {
        logger.warn("[Migration] Firebase Auth에 기존 유저 없음", { originalSub, error });
        // Firebase Auth에 없으면 Firestore만 확인
      }

      // 3. Firestore에서 기존 사용자 문서 찾기
      const originalUserDoc = await db.collection("users").doc(originalSub).get();

      if (!originalUserDoc.exists) {
        logger.warn("[Migration] Firestore에 기존 유저 문서 없음", { originalSub });
        return {
          success: false,
          message: "Original user document not found in Firestore",
          migratedFrom: originalSub,
        };
      }

      const originalUserData = originalUserDoc.data();
      logger.info("[Migration] 기존 유저 데이터 찾음", {
        originalSub,
        originalEmail: originalUserData?.email,
        originalName: originalUserData?.name,
      });

      // 4. 현재 UID로 생성된 문서가 있는지 확인 (신규 유저로 잘못 생성된 문서)
      const currentUserDoc = await db.collection("users").doc(currentUid).get();

      if (currentUserDoc.exists) {
        // 현재 UID 문서 삭제 (중복 방지)
        logger.info("[Migration] 현재 UID 문서 삭제", { currentUid });
        await db.collection("users").doc(currentUid).delete();
      }

      // 5. 기존 문서에 새 UID 정보 업데이트 (필요시)
      // 주의: Firebase Auth의 UID는 변경할 수 없으므로,
      // 앱에서는 originalSub을 UID로 사용하도록 재로그인 필요

      // email/name 업데이트 (Private Email 대응)
      const updateData: any = {
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      };

      if (email && email !== originalUserData?.email) {
        updateData.email = email;
        logger.info("[Migration] 이메일 업데이트", { oldEmail: originalUserData?.email, newEmail: email });
      }

      if (name && name !== originalUserData?.name && originalUserData?.name !== "Unknown") {
        // 기존 이름이 "Unknown"이 아니면 유지
        logger.info("[Migration] 기존 이름 유지", { originalName: originalUserData?.name });
      } else if (name) {
        updateData.name = name;
        logger.info("[Migration] 이름 업데이트", { oldName: originalUserData?.name, newName: name });
      }

      await db.collection("users").doc(originalSub).update(updateData);
      logger.info("[Migration] 사용자 데이터 업데이트 완료", { originalSub, updateData });

      return {
        success: true,
        message: "Migration successful",
        migratedFrom: originalSub,
        originalEmail: originalUserData?.email,
        originalName: originalUserData?.name,
      };

    } catch (error) {
      logger.error("[Migration] 실패", { error, transferSub, currentUid });
      throw new HttpsError("internal", "Migration failed", error);
    }
  }
);

/**
 * =============================================================================
 * Account Recovery for 1.1.5 Users
 * =============================================================================
 */

/**
 * Step 1: 이름으로 후보 계정 찾고 팀스페이스 검증 문제 생성
 */
export const findAccountForRecovery = onCall(async (request) => {
  const { userName, currentUid } = request.data;

  logger.info("[AccountRecovery] 계정 검색 시작", { userName, currentUid });

  // 1. 이름으로 후보 찾기
  const candidates = await db.collection("users")
    .where("name", "==", userName)
    .get();

  if (candidates.empty) {
    logger.warn("[AccountRecovery] 후보 없음", { userName });
    return {
      found: false,
      message: "해당 이름의 계정을 찾을 수 없습니다",
    };
  }

  // 동명이인이 있을 수 있으므로 첫 번째만 사용
  const candidate = candidates.docs[0];
  const candidateUserId = candidate.id;

  logger.info("[AccountRecovery] 후보 발견", { candidateUserId });

  // 2. 후보의 팀스페이스 조회
  const realTeamspaces: Array<{id: string, name: string}> = [];

  // 사용자가 속한 모든 팀스페이스 찾기
  const allTeamspaces = await db.collection("teamspace").get();
  logger.info("[AccountRecovery] 전체 팀스페이스 조회", {
    totalTeamspaces: allTeamspaces.size
  });

  for (const ts of allTeamspaces.docs) {
    const memberDoc = await ts.ref.collection("members").doc(candidateUserId).get();
    logger.info("[AccountRecovery] members 체크", {
      teamspaceId: ts.id,
      teamspaceName: ts.data().teamspace_name,
      memberExists: memberDoc.exists,
      candidateUserId
    });

    if (memberDoc.exists) {
      realTeamspaces.push({
        id: ts.id,
        name: ts.data().teamspace_name,
      });
    }
  }

  if (realTeamspaces.length === 0) {
    logger.warn("[AccountRecovery] 팀스페이스 없음", { candidateUserId });
    return {
      found: false,
      message: "계정을 찾았으나 팀스페이스가 없습니다. 고객센터로 문의해주세요.",
    };
  }

  // 3. 가짜 팀스페이스 추가 (다른 사람 것)
  const fakeTeamspaces: Array<{id: string, name: string}> = [];
  const otherTeamspaces = allTeamspaces.docs
    .filter((ts) => !realTeamspaces.some((rt) => rt.id === ts.id))
    .slice(0, 2);  // 가짜 2개만

  for (const ts of otherTeamspaces) {
    fakeTeamspaces.push({
      id: ts.id,
      name: ts.data().teamspace_name,
    });
  }

  // 4. 섞어서 반환 (3개)
  const allOptions = [...realTeamspaces, ...fakeTeamspaces]
    .sort(() => Math.random() - 0.5)  // 랜덤 섞기
    .slice(0, 3);

  logger.info("[AccountRecovery] 검증 문제 생성", {
    candidateUserId,
    realCount: realTeamspaces.length,
    options: allOptions.length,
  });

  return {
    found: true,
    candidateUserId: candidateUserId,
    teamspaceOptions: allOptions,
    correctTeamspaceIds: realTeamspaces.map((t) => t.id),  // 클라이언트에는 안 보냄
  };
});

/**
 * Step 2: 팀스페이스 선택 검증 및 계정 복구 실행
 */
export const verifyAndRecoverAccount = onCall(async (request) => {
  const { candidateUserId, selectedTeamspaceId, currentUid, correctTeamspaceIds } = request.data;

  logger.info("[AccountRecovery] 검증 시작", {
    candidateUserId,
    selectedTeamspaceId,
    currentUid,
  });

  // 1. 정답 확인
  const isCorrect = correctTeamspaceIds.includes(selectedTeamspaceId);

  if (!isCorrect) {
    logger.warn("[AccountRecovery] 잘못된 선택", { selectedTeamspaceId, correctTeamspaceIds });
    return {
      success: false,
      message: "선택이 올바르지 않습니다. 다시 시도해주세요.",
    };
  }

  logger.info("[AccountRecovery] 검증 성공, 복구 시작");

  try {
    // 2. 기존 계정 데이터 가져오기
    const oldUserDoc = await db.collection("users").doc(candidateUserId).get();
    if (!oldUserDoc.exists) {
      throw new Error("Original user not found");
    }

    const oldUserData = oldUserDoc.data()!;

    // 3. currentUid에 기존 데이터 덮어쓰기 (userId만 변경)
    await db.collection("users").doc(currentUid).set({
      ...oldUserData,
      user_id: currentUid,  // ← 새 UID로 변경
      country: oldUserData.country || "kr",  // ← country 필드 없으면 기본값 추가
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    logger.info("[AccountRecovery] users 문서 복구 완료");

    // 3-1. 서브컬렉션 복사 (user_teamspace, user_notification)
    await copyUserSubcollections(candidateUserId, currentUid);

    // 4. 모든 참조 업데이트
    await updateAllReferences(candidateUserId, currentUid);

    // 5. 기존 계정을 Soft Delete (나중에 수동 확인/삭제 가능)
    // 이메일과 이름에 _migrated를 붙여 충돌 방지
    await db.collection("users").doc(candidateUserId).update({
      status: "migrated",
      email: `${oldUserData.email}_migrated`,
      name: `${oldUserData.name}_migrated`,
      migrated_to: currentUid,
      migrated_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    logger.info("[AccountRecovery] 계정 복구 완료 (기존 계정은 migrated 상태로 유지)", {
      oldUserId: candidateUserId,
      newUserId: currentUid,
    });

    // 6. 관리자에게 이메일 알림 발송
    try {
      const recoveredUser = await db.collection("users").doc(currentUid).get();
      const userData = recoveredUser.data();

      const transporter = nodemailer.createTransport({
        service: "gmail",
        auth: {
          user: gmailUser.value(),
          pass: gmailPassword.value(),
        },
      });

      const mailOptions = {
        from: gmailUser.value(),
        to: gmailUser.value(),
        subject: "[DirAct 계정 복구] 계정 복구 완료 알림",
        html: `
          <h2>DirAct 계정 복구 완료</h2>
          <p><strong>사용자 이름:</strong> ${userData?.name || "Unknown"}</p>
          <p><strong>이메일:</strong> ${userData?.email || "N/A"}</p>
          <p><strong>기존 UID:</strong> ${candidateUserId}</p>
          <p><strong>새 UID:</strong> ${currentUid}</p>
          <p><strong>복구 시간:</strong> ${new Date().toLocaleString("ko-KR")}</p>
          <hr>
          <p>사용자가 계정 복구를 성공적으로 완료했습니다.</p>
        `,
      };

      await transporter.sendMail(mailOptions);
      logger.info("[AccountRecovery] 이메일 발송 성공", { currentUid });
    } catch (emailError) {
      logger.error("[AccountRecovery] 이메일 발송 실패", { emailError });
      // 이메일 실패는 복구 성공에 영향을 주지 않음
    }

    return {
      success: true,
      message: "계정이 성공적으로 복구되었습니다.",
    };
  } catch (error) {
    logger.error("[AccountRecovery] 복구 실패", { error });
    throw new HttpsError("internal", "Account recovery failed", error);
  }
});

/**
 * Helper: 모든 컬렉션의 userId 참조 업데이트
 */
async function updateAllReferences(oldUserId: string, newUserId: string) {
  const batch = db.batch();
  let batchCount = 0;

  const commitBatch = async () => {
    if (batchCount > 0) {
      await batch.commit();
      batchCount = 0;
    }
  };

  logger.info("[AccountRecovery] 참조 업데이트 시작", { oldUserId, newUserId });

  // 1. teamspace - ownerId
  const teamspaces = await db.collection("teamspace")
    .where("owner_id", "==", oldUserId)
    .get();
  for (const ts of teamspaces.docs) {
    batch.update(ts.ref, { owner_id: newUserId });
    batchCount++;
    if (batchCount >= 500) await commitBatch();
  }

  // 2. teamspace/{id}/members - userId (서브컬렉션)
  const allTeamspaces = await db.collection("teamspace").get();
  for (const ts of allTeamspaces.docs) {
    const memberDoc = await ts.ref.collection("members").doc(oldUserId).get();
    if (memberDoc.exists) {
      // 기존 멤버 데이터 가져오기
      const memberData = memberDoc.data() || {};

      // 기존 멤버 삭제
      await ts.ref.collection("members").doc(oldUserId).delete();

      // 새 UID로 재생성 (모든 필드 복사하고 user_id만 업데이트)
      await ts.ref.collection("members").doc(newUserId).set({
        ...memberData,
        user_id: newUserId,
      });
    }
  }

  // 3. project - creatorId
  const projects = await db.collection("project")
    .where("creator_id", "==", oldUserId)
    .get();
  for (const proj of projects.docs) {
    batch.update(proj.ref, { creator_id: newUserId });
    batchCount++;
    if (batchCount >= 500) await commitBatch();
  }

  // 4. tracks - creatorId
  const tracks = await db.collection("tracks")
    .where("creator_id", "==", oldUserId)
    .get();
  for (const track of tracks.docs) {
    batch.update(track.ref, { creator_id: newUserId });
    batchCount++;
    if (batchCount >= 500) await commitBatch();
  }

  // 5. video - uploaderId
  const videos = await db.collection("video")
    .where("uploader_id", "==", oldUserId)
    .get();
  for (const vid of videos.docs) {
    batch.update(vid.ref, { uploader_id: newUserId });
    batchCount++;
    if (batchCount >= 500) await commitBatch();
  }

  // 6. feedback - authorId, taggedUserIds
  const feedbacks = await db.collection("feedback")
    .where("author_id", "==", oldUserId)
    .get();
  for (const fb of feedbacks.docs) {
    batch.update(fb.ref, { author_id: newUserId });
    batchCount++;
    if (batchCount >= 500) await commitBatch();
  }

  const taggedFeedbacks = await db.collection("feedback")
    .where("tagged_user_ids", "array-contains", oldUserId)
    .get();
  for (const fb of taggedFeedbacks.docs) {
    const taggedIds = fb.data().tagged_user_ids || [];
    const updatedIds = taggedIds.map((id: string) => id === oldUserId ? newUserId : id);
    batch.update(fb.ref, { tagged_user_ids: updatedIds });
    batchCount++;
    if (batchCount >= 500) await commitBatch();
  }

  // 7. feedback/{id}/reply - authorId, taggedUserIds (서브컬렉션)
  const allFeedbacks = await db.collection("feedback").get();
  for (const fb of allFeedbacks.docs) {
    const replies = await fb.ref.collection("reply")
      .where("author_id", "==", oldUserId)
      .get();
    for (const reply of replies.docs) {
      batch.update(reply.ref, { author_id: newUserId });
      batchCount++;
      if (batchCount >= 500) await commitBatch();
    }

    const taggedReplies = await fb.ref.collection("reply")
      .where("tagged_user_ids", "array-contains", oldUserId)
      .get();
    for (const reply of taggedReplies.docs) {
      const taggedIds = reply.data().tagged_user_ids || [];
      const updatedIds = taggedIds.map((id: string) => id === oldUserId ? newUserId : id);
      batch.update(reply.ref, { tagged_user_ids: updatedIds });
      batchCount++;
      if (batchCount >= 500) await commitBatch();
    }
  }

  // 8. notification - senderId, receiverIds
  const senderNotifs = await db.collection("notification")
    .where("sender_id", "==", oldUserId)
    .get();
  for (const notif of senderNotifs.docs) {
    batch.update(notif.ref, { sender_id: newUserId });
    batchCount++;
    if (batchCount >= 500) await commitBatch();
  }

  const receiverNotifs = await db.collection("notification")
    .where("receiver_ids", "array-contains", oldUserId)
    .get();
  for (const notif of receiverNotifs.docs) {
    const receiverIds = notif.data().receiver_ids || [];
    const updatedIds = receiverIds.map((id: string) => id === oldUserId ? newUserId : id);
    batch.update(notif.ref, { receiver_ids: updatedIds });
    batchCount++;
    if (batchCount >= 500) await commitBatch();
  }

  // 9. report - reporterId, reportedId
  const reporterReports = await db.collection("report")
    .where("reporter_id", "==", oldUserId)
    .get();
  for (const report of reporterReports.docs) {
    batch.update(report.ref, { reporter_id: newUserId });
    batchCount++;
    if (batchCount >= 500) await commitBatch();
  }

  const reportedReports = await db.collection("report")
    .where("reported_id", "==", oldUserId)
    .get();
  for (const report of reportedReports.docs) {
    batch.update(report.ref, { reported_id: newUserId });
    batchCount++;
    if (batchCount >= 500) await commitBatch();
  }

  // 10. invites - inviterId
  const invites = await db.collection("invites")
    .where("inviter_id", "==", oldUserId)
    .get();
  for (const invite of invites.docs) {
    batch.update(invite.ref, { inviter_id: newUserId });
    batchCount++;
    if (batchCount >= 500) await commitBatch();
  }

  // 11. users/{oldUserId}/blocks → users/{newUserId}/blocks (서브컬렉션 이동)
  const blocks = await db.collection("users").doc(oldUserId).collection("blocks").get();
  for (const block of blocks.docs) {
    await db.collection("users").doc(newUserId).collection("blocks").doc(block.id).set(block.data());
    await block.ref.delete();
  }

  // 12. 다른 사람이 oldUserId를 차단한 경우
  const allUsers = await db.collection("users").get();
  for (const user of allUsers.docs) {
    const blockDoc = await user.ref.collection("blocks").doc(oldUserId).get();
    if (blockDoc.exists) {
      await user.ref.collection("blocks").doc(oldUserId).delete();
      await user.ref.collection("blocks").doc(newUserId).set({
        blocked_user_id: newUserId,
      });
    }
  }

  await commitBatch();
  logger.info("[AccountRecovery] 모든 참조 업데이트 완료");
}

/**
 * Helper: users 서브컬렉션 복사 (user_teamspace, user_notification)
 */
async function copyUserSubcollections(oldUserId: string, newUserId: string) {
  logger.info("[AccountRecovery] 서브컬렉션 복사 시작", { oldUserId, newUserId });

  // 1. user_teamspace 서브컬렉션 복사
  const userTeamspaces = await db.collection("users")
    .doc(oldUserId)
    .collection("user_teamspace")
    .get();

  for (const doc of userTeamspaces.docs) {
    await db.collection("users")
      .doc(newUserId)
      .collection("user_teamspace")
      .doc(doc.id)
      .set(doc.data());
  }

  logger.info("[AccountRecovery] user_teamspace 복사 완료", {
    count: userTeamspaces.size,
  });

  // 2. user_notification 서브컬렉션 복사
  const userNotifications = await db.collection("users")
    .doc(oldUserId)
    .collection("user_notification")
    .get();

  for (const doc of userNotifications.docs) {
    await db.collection("users")
      .doc(newUserId)
      .collection("user_notification")
      .doc(doc.id)
      .set(doc.data());
  }

  logger.info("[AccountRecovery] user_notification 복사 완료", {
    count: userNotifications.size,
  });
}

/**
 * Helper: users 문서 및 서브컬렉션 삭제
 *
 * NOTE: Soft delete 정책으로 변경되어 현재 사용하지 않음.
 * 나중에 수동으로 migrated 계정을 삭제할 때 사용 가능.
 *
 * @internal - 수동 관리용으로만 export
 */
export async function deleteUserWithSubcollections(userId: string) {
  logger.info("[AccountRecovery] 사용자 삭제 시작 (서브컬렉션 포함)", { userId });

  // 1. user_teamspace 서브컬렉션 삭제
  const userTeamspaces = await db.collection("users")
    .doc(userId)
    .collection("user_teamspace")
    .get();

  for (const doc of userTeamspaces.docs) {
    await doc.ref.delete();
  }

  // 2. user_notification 서브컬렉션 삭제
  const userNotifications = await db.collection("users")
    .doc(userId)
    .collection("user_notification")
    .get();

  for (const doc of userNotifications.docs) {
    await doc.ref.delete();
  }

  // 3. users 문서 삭제
  await db.collection("users").doc(userId).delete();

  logger.info("[AccountRecovery] 사용자 삭제 완료", { userId });
}
