/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https"
 * import {onDocumentWritten} from "firebase-functions/v2/firestore"
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

// Start writing functions
// https://firebase.google.com/docs/functions/typescript


// The Cloud Functions for Firebase SDK to create Cloud Functions and triggers.
// The Firebase Admin SDK to access Firestore.
import * as admin from "firebase-admin"
import { onDocumentCreated } from "firebase-functions/v2/firestore"
import { setGlobalOptions } from "firebase-functions"
import * as logger from "firebase-functions/logger"
import { josa } from "es-hangul"
import { v4 as uuidv4 } from "uuid"


admin.initializeApp()
setGlobalOptions({ region: "asia-northeast3", maxInstances: 10 })


const db = admin.firestore()
const fcm = admin.messaging()


/**
 * 특정 수신자(receiverId)가 발신자(senderId)를 차단했는지 확인
 *
 * @param {string} receiverId - 수신자 id
 * @param {string} senderId - 발신자 id
 */
async function isUserBlockedBy(receiverId: string, senderId: string): Promise<boolean> {
  const blockDoc = await db
    .collection("users")
    .doc(receiverId)
    .collection("blocks")
    .doc(senderId)
    .get()
  return blockDoc.exists
}

/**
 * FCM 푸시 알림 전송 (여러명에게 알림 전송 가능)
 *
 * @param {string} receiverIds - 수신자 id 배열
 * @param {string} title - 알림 제목
 * @param {string} body - 알림 내용
 */
async function sendPushNotification(receiverIds: string[], title: string, body: string) {
  if (!receiverIds.length) {
    logger.error("No receiverIds for push", { receiverIds })
    return
  }

  // Warning: receiverIds must no more than 30
  // see https://firebase.google.com/docs/firestore/query-data/queries?hl=ko#in_not-in_and_array-contains-any
  const usersSnap = await db
    .collection("users")
    .where(admin.firestore.FieldPath.documentId(), "in", receiverIds)
    .get()

  const tokens = usersSnap.docs
    .map((doc) => doc.get("fcm_token"))
    .filter((token) => typeof token === "string" && token.length > 0)
  if (!tokens.length) {
    logger.error("No FCM tokens found for receivers", { receiverIds })
    return
  }


  const message: admin.messaging.MulticastMessage = {
    notification: { title, body },
    tokens,
  }

  try {
    await fcm.sendEachForMulticast(message)
    logger.info("Push notification sent", { tokens, title, body })
  } catch (error) {
    logger.error("Push notification send error", error)
  }
}

/**
 * feedback 문서 생성 시 알림
 * feedback 문서 생성됨 - 태그된 사람 있는지 확인 - 태그된 사람 중 작성자를 차단한 사람 필터링 - 필터링한 사람한테만 보낼 notification 문서 생성 - 문서 기반으로 푸시 알림 보냄
 */
export const onFeedbackCreated = onDocumentCreated("feedback/{feedbackId}", async (event) => {
  const snap = event.data
  if (!snap) {
    logger.error("No feedback doc found", { eventId: event.id })
    return
  }
  const feedback = snap.data()

  const { feedback_id, author_id, tagged_user_ids, content, video_id } = feedback

  if (!tagged_user_ids || tagged_user_ids.length === 0) {
    logger.info("No tagged users, skipping notification", { feedback_id })
    return
  }

  const validTaggedUsers: string[] = []
  await Promise.all(
    tagged_user_ids.map(async (receiverId: string) => {
      const blocked = await isUserBlockedBy(receiverId, author_id)
      if (!blocked) validTaggedUsers.push(receiverId)
    })
  )

  logger.debug("Valid tagged users after block filter", { validTaggedUsers })

  if (validTaggedUsers.length === 0) {
    logger.info("No valid tagged users after block filter", { feedback_id })
    return
  }

 const notification_id = String(uuidv4()).toUpperCase();

 await db.collection("notification").doc(notification_id).set({
    notification_id,
    sender_id: author_id,
    receiver_ids: validTaggedUsers,
    feedback_id,
    created_at: admin.firestore.FieldValue.serverTimestamp(),
    video_id,
    content,
  })
  logger.info("Notification doc created by feedback", { feedback_id, validTaggedUsers })

  const authorDoc = await db.collection("users").doc(author_id).get()
  const name = authorDoc.exists ? authorDoc.get("name") : null
  if (!name) {
    logger.warn("Author name not found", { author_id })
    return
  }

  const title = `${josa(name, "이/가")} 피드백을 남겼어요`
  const body = content.slice(0, 50) // FIXME: 글자수 제한

  await sendPushNotification(validTaggedUsers, title, body)
  logger.info("Push notification sent for feedback", { validTaggedUsers, title, body })
})

/**
 * reply 문서 생성 시 알림
 *
 */
export const onReplyCreated = onDocumentCreated("reply/{replyId}", async (event) => {
  const snap = event.data
  if (!snap) {
    logger.warn("No reply doc found", { eventId: event.id })
    return
  }

  const reply = snap.data()
  const { reply_id, feedback_id, author_id, tagged_user_ids, content } = reply
  if (!tagged_user_ids || tagged_user_ids.length === 0) {
    logger.info("No tagged users in reply, skipping notification", { reply_id })
    return
  }

  const feedbackDoc = await db.collection("feedback").doc(feedback_id).get()
  const feedbackDoc_author_id = feedbackDoc.exists ? feedbackDoc.get("author_id") : null
  const video_id = feedbackDoc.exists ? feedbackDoc.get("video_id") : null
  if (!feedbackDoc_author_id || !video_id) {
    logger.error("Feedback author_id or video_id not found", { feedback_id, feedbackDoc_author_id, video_id })
    return
  }


  const validTaggedUsers: string[] = []
  await Promise.all(
    tagged_user_ids.map(async (receiverId: string) => {
      const blocked = await isUserBlockedBy(receiverId, author_id)
      if (!blocked) validTaggedUsers.push(receiverId)
    })
  )
  logger.debug("Valid tagged users after block filter", { validTaggedUsers })

  // 피드백 작성자와 댓글 작성자가 같고 태그된 사용자 중 유효하게 알림을 보내야할 사람이 없으면 종료
  if (feedbackDoc_author_id === author_id && validTaggedUsers.length === 0) {
    logger.info("Reply author equals to feedback author and no valid tagged users, skipping notification", { reply_id })
    return
  }

  let validReceivers = feedbackDoc_author_id === author_id ?
    validTaggedUsers : // (1) 자기 피드백에 댓글 → 태그된 사람만
    validTaggedUsers.length === 0 ?
      [feedbackDoc_author_id] : // (2) 남의 피드백 + 태그 없음 → 피드백 작성자만
      [feedbackDoc_author_id, ...validTaggedUsers] // (3) 남의 피드백 + 태그 있음 → 피드백 작성자 + 태그된 사람

  // 댓글 작성자는 댓글로 인해 알림 받지 않도록 하는 조치 (클라이언트 버그 방지)
  validReceivers = [...new Set(validReceivers)].filter((id) => id !== author_id)
  logger.debug("Final valid receivers for reply notification", { validReceivers })

  if (validReceivers.length === 0) {
    logger.info("No valid receivers for reply notification", { reply_id })
    return
  }

 const notification_id = String(uuidv4()).toUpperCase();

 await db.collection("notification").doc(notification_id).set({
    notification_id,
    sender_id: author_id,
    receiver_ids: validReceivers,
    feedback_id,
    created_at: admin.firestore.FieldValue.serverTimestamp(),
    video_id,
    content,
  })
  logger.info("Notification doc created by reply", { reply_id, validReceivers })

  const authorDoc = await db.collection("users").doc(author_id).get()
  const name = authorDoc.exists ? authorDoc.get("name") : null
  if (!name) {
    logger.error("Reply author name not found", { author_id })
    return
  }

  const title = `${josa(name, "이/가")} 댓글을 남겼어요`
  const body = content.slice(0, 50) // FIXME: 글자수 제한

  await sendPushNotification(validReceivers, title, body)
  logger.info("Push notification sent for reply", { validReceivers, title, body })
})
