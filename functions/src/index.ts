import * as admin from "firebase-admin";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { setGlobalOptions } from "firebase-functions";
import * as logger from "firebase-functions/logger";
import { josa } from "es-hangul";
import { v4 as uuidv4 } from "uuid";

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
 * @param extra 추가 데이터 (video_id, video_title, video_url, notification_id)
 */
async function sendPushNotificationsWithBadge(
  receivers: string[],
  title: string,
  body: string,
  extra: { video_id: string; video_title: string; video_url: string, notification_id: string }
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
      const qSnap = await db
        .collection("users").doc(uid)
        .collection("user_notification")
        .where("created_at", ">=", oneMonthAgo)
        .where("is_read", "==", false)
        .get();

      return { uid, unreadCount: qSnap.size };
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
      if (!token || typeof token !== "string" || token.length === 0) {
        logger.warn("FCM token missing for user", { uid });
      }

      // 딥링크 생성
      let deeplink = "";
      const encodedTitle = encodeURIComponent(extra.video_title);
      const encodedUrl = encodeURIComponent(extra.video_url);
      deeplink = `${URL_SCHEME}://video/view?videoId=${extra.video_id}&videoTitle=${encodedTitle}&videoURL=${encodedUrl}`;
      

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
    logger.error("onFeedbackCreated: no snapshot", { eventId: event.id });
    return;
  }
  const feedback = snap.data();

  const { feedback_id, author_id, tagged_user_ids, content, video_id, teamspace_id } = feedback;

  if (!tagged_user_ids || tagged_user_ids.length === 0) {
    logger.error("onFeedbackCreated: no tagged users", { feedback_id });
    return;
  }

  const validTaggedUsers: string[] = [];
  await Promise.all(
    tagged_user_ids.map(async (receiverId: string) => {
      const blocked = await isUserBlockedBy(receiverId, author_id);
      if (!blocked) validTaggedUsers.push(receiverId);
    })
  );

  logger.debug("Valid tagged users after block filter", { validTaggedUsers });

  if (validTaggedUsers.length === 0) {
    logger.error("onFeedbackCreated: no valid tagged users after filter", { feedback_id });
    return;
  }

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
  logger.info("Notification doc created (feedback)", { feedback_id, validTaggedUsers, notification_id });

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
  logger.info("user_notification documents created (feedback)", { validTaggedUsers });

  // 푸시 전송
  const authorDoc = await db.collection("users").doc(author_id).get();
  const name = authorDoc.exists ? authorDoc.get("name") : null;
  if (!name) {
    logger.error("Author name not found", { author_id });
    return;
  }
  const videoDoc = await db.collection("video").doc(video_id).get();
  const video_title = videoDoc.exists ? videoDoc.get("video_title") : null;
  const video_url = videoDoc.exists ? videoDoc.get("video_url") : null;
  if (!video_title || !video_url) {
    logger.error("Video info not found", { video_id });
    return;
  }

  const title = `${josa(name, "이/가")} 피드백을 남겼어요`;
  const body = content;
  const extra = { video_id, video_title, video_url, notification_id };

  await sendPushNotificationsWithBadge(validTaggedUsers, title, body, extra);
  logger.info("Push notification process completed (feedback)", { validTaggedUsers, title, body, extra });
});

/**
 * reply 문서 생성 시 알림 처리 트리거
 */
export const onReplyCreated = onDocumentCreated("feedback/{feedbackId}/reply/{replyId}", async (event) => {
  const snap = event.data;
  if (!snap) {
    logger.error("onReplyCreated: no snapshot", { eventId: event.id });
    return;
  }
  const reply = snap.data();
  const { reply_id, feedback_id, author_id, tagged_user_ids, content } = reply;

  const feedbackDoc = await db.collection("feedback").doc(feedback_id).get();
  const feedbackAuthorId = feedbackDoc.exists ? feedbackDoc.get("author_id") : null;
  const teamspace_id = feedbackDoc.exists ? feedbackDoc.get("teamspace_id") : null;
  const video_id = feedbackDoc.exists ? feedbackDoc.get("video_id") : null;
  if (!feedbackAuthorId || !teamspace_id || !video_id) {
    logger.error("Feedback doc incomplete", { feedback_id, feedbackAuthorId, teamspace_id, video_id });
    return;
  }

  const validTaggedUsers: string[] = [];
  await Promise.all(
    tagged_user_ids.map(async (receiverId: string) => {
      const blocked = await isUserBlockedBy(receiverId, author_id);
      if (!blocked) validTaggedUsers.push(receiverId);
    })
  );
  logger.debug("Valid tagged users after block filter (reply)", { validTaggedUsers });

  // 피드백 작성자 == 댓글 작성자 && 태그된 사용자 없음 → 알림 없음
  if (feedbackAuthorId === author_id && validTaggedUsers.length === 0) {
    logger.info("Reply author equals to feedback author and no valid tagged users, skipping notification", { reply_id })
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
    logger.info("onReplyCreated: no valid receivers", { reply_id });
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
  logger.info("Notification doc created (reply)", { reply_id, validReceivers, notification_id });

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
  logger.info("user_notification documents created (reply)", { validReceivers });

  const authorDoc = await db.collection("users").doc(author_id).get();
  const name = authorDoc.exists ? authorDoc.get("name") : null;
  if (!name) {
    logger.error("Reply author name not found", { author_id });
    return;
  }
  const videoDoc = await db.collection("video").doc(video_id).get();
  const video_title = videoDoc.exists ? videoDoc.get("video_title") : null;
  const video_url = videoDoc.exists ? videoDoc.get("video_url") : null;
  if (!video_title || !video_url) {
    logger.error("Video info not found", { video_id });
    return;
  }

  const title = `${josa(name, "이/가")} 댓글을 남겼어요`;
  const body = content;
  const extra = { video_id, video_title, video_url, notification_id };

  await sendPushNotificationsWithBadge(validReceivers, title, body, extra);
  logger.info("Push notification process completed (reply)", { validReceivers, title, body, extra });
});
