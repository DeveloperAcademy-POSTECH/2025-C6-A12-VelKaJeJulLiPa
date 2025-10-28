//
//  MockData.swift
//  DanceMachine
//
//  Created by 김진혁 on 10/13/25.
//

import Foundation

struct MockData {
    static let userId: String = "4A7DE503-6362-49FF-B110-78E66AECECB8"
    //static let userId: String = "6341C3A3-6CA5-46E2-BE12-DB1F5A76B508"
}

// 4A7DE503-6362-49FF-B110-78E66AECECB8 김벨코
// 6341C3A3-6CA5-46E2-BE12-DB1F5A76B508 조카단

private let Mock_Notification: [Notification] = [
    //MARK: - 10개
    Notification(
        notificationId: UUID(),
        senderId: "HqU0UNmrS5UBhxKZjhz4wqku4XB3",
        receiverIds: ["MyYdLZPoWjb3D8TvWfQLfx1wYf82"],
        feedbackId: "07F0C9A3-2C33-46C7-94C6-CCFAE7B75CF7",
        replyId: nil,
        createdAt: Date.now,
        videoId: "030585AF-DAB9-4584-8574-FCAA057C740D",
        content: "Lorem Ipsum is simply dummy text of the printing and typesetting industry..."
    ),
    Notification(
        notificationId: UUID(),
        senderId: "39GGxwlYpWe8bamRae2Cfj168F63",
        receiverIds: ["MyYdLZPoWjb3D8TvWfQLfx1wYf82"],
        feedbackId: "07F0C9A3-2C33-46C7-94C6-CCFAE7B75CF7",
        replyId: nil,
        createdAt: Date.now,
        videoId: "EB6EB151-3DCC-44E7-9A73-6514FC3F176B",
        content: "나는 이제 너에게도 슬픔을 주겠다."
    ),
    Notification(
        notificationId: UUID(),
        senderId: "HqU0UNmrS5UBhxKZjhz4wqku4XB3",
        receiverIds: ["MyYdLZPoWjb3D8TvWfQLfx1wYf82"],
        feedbackId: "07F0C9A3-2C33-46C7-94C6-CCFAE7B75CF7",
        replyId: nil,
        createdAt: Date.now,
        videoId: "EB6EB151-3DCC-44E7-9A73-6514FC3F176B",
        content: "사랑보다 소중한 슬픔을 주겠다."
    ),
    Notification(
        notificationId: UUID(),
        senderId: "39GGxwlYpWe8bamRae2Cfj168F63",
        receiverIds: ["MyYdLZPoWjb3D8TvWfQLfx1wYf82"],
        feedbackId: "07F0C9A3-2C33-46C7-94C6-CCFAE7B75CF7",
        replyId: nil,
        createdAt: Date.now,
        videoId: "EB6EB151-3DCC-44E7-9A73-6514FC3F176B",
        content: "겨울밤 거리에서 귤 몇 개 놓고"
    ),
    Notification(
        notificationId: UUID(),
        senderId: "HqU0UNmrS5UBhxKZjhz4wqku4XB3",
        receiverIds: ["MyYdLZPoWjb3D8TvWfQLfx1wYf82"],
        feedbackId: "07F0C9A3-2C33-46C7-94C6-CCFAE7B75CF7",
        replyId: nil,
        createdAt: Date.now,
        videoId: "EB6EB151-3DCC-44E7-9A73-6514FC3F176B",
        content: "귤값을 깎으면서 기뻐하던 너를 위하여"
    ),
    Notification(
        notificationId: UUID(),
        senderId: "HqU0UNmrS5UBhxKZjhz4wqku4XB3",
        receiverIds: ["MyYdLZPoWjb3D8TvWfQLfx1wYf82"],
        feedbackId: "07F0C9A3-2C33-46C7-94C6-CCFAE7B75CF7",
        replyId: nil,
        createdAt: Date.now,
        videoId: "EB6EB151-3DCC-44E7-9A73-6514FC3F176B",
        content: "나는 슬픔의 평등한 얼굴을 보여주겠다."
    ),
    Notification(
        notificationId: UUID(),
        senderId: "wR6SLGIakuVZtYl6jCjge0JRPsF2",
        receiverIds: ["MyYdLZPoWjb3D8TvWfQLfx1wYf82"],
        feedbackId: "UUID7",
        replyId: nil,
        createdAt: Date.now,
        videoId: "EB6EB151-3DCC-44E7-9A73-6514FC3F176B",
        content: "가야 할 때가 언제인가를 분명히 알고 가는 이의 뒷모습은 얼마나 아름다운가"
    ),
    Notification(
        notificationId: UUID(),
        senderId: "39GGxwlYpWe8bamRae2Cfj168F63",
        receiverIds: ["MyYdLZPoWjb3D8TvWfQLfx1wYf82"],
        feedbackId: "07F0C9A3-2C33-46C7-94C6-CCFAE7B75CF7",
        replyId: nil,
        createdAt: Date.now,
        videoId: "EB6EB151-3DCC-44E7-9A73-6514FC3F176B",
        content: "시를 잊은 그대에게"
    ),
    Notification(
        notificationId: UUID(),
        senderId: "HqU0UNmrS5UBhxKZjhz4wqku4XB3",
        receiverIds: ["MyYdLZPoWjb3D8TvWfQLfx1wYf82"],
        feedbackId: "07F0C9A3-2C33-46C7-94C6-CCFAE7B75CF7",
        replyId: nil,
        createdAt: Date.now,
        videoId: "EB6EB151-3DCC-44E7-9A73-6514FC3F176B",
        content: "나는야 아이퍼. 나는 대단해 나는 최고야!"
    ),
    
    //MARK: - 20개
    Notification(
        notificationId: UUID(),
        senderId: "HqU0UNmrS5UBhxKZjhz4wqku4XB3",
        receiverIds: ["MyYdLZPoWjb3D8TvWfQLfx1wYf82"],
        feedbackId: "07F0C9A3-2C33-46C7-94C6-CCFAE7B75CF7",
        replyId: nil,
        createdAt: Date.now,
        videoId: "EB6EB151-3DCC-44E7-9A73-6514FC3F176B",
        content: "🔥🔧✨🧑‍💻 이모지 여러개 실험중...]"
    ),
    Notification(
        notificationId: UUID(),
        senderId: "HqU0UNmrS5UBhxKZjhz4wqku4XB3",
        receiverIds: ["MyYdLZPoWjb3D8TvWfQLfx1wYf82"],
        feedbackId: "07F0C9A3-2C33-46C7-94C6-CCFAE7B75CF7",
        replyId: nil,
        createdAt: Date.now,
        videoId: "EB6EB151-3DCC-44E7-9A73-6514FC3F176B",
        content: "Lorem Ipsum..."
    ),
    Notification(
        notificationId: UUID(),
        senderId: "HqU0UNmrS5UBhxKZjhz4wqku4XB3",
        receiverIds: ["MyYdLZPoWjb3D8TvWfQLfx1wYf82"],
        feedbackId: "07F0C9A3-2C33-46C7-94C6-CCFAE7B75CF7",
        replyId: nil,
        createdAt: Date.now,
        videoId: "EB6EB151-3DCC-44E7-9A73-6514FC3F176B",
        content: "가야 할 때가 언제인가를 분명히 알고 가는 이의 뒷모습은 얼마나 아름다운가."
    ),
    Notification(
        notificationId: UUID(),
        senderId: "39GGxwlYpWe8bamRae2Cfj168F63",
        receiverIds: ["MyYdLZPoWjb3D8TvWfQLfx1wYf82"],
        feedbackId: "UUID13",
        replyId: nil,
        createdAt: Date.now,
        videoId: "EB6EB151-3DCC-44E7-9A73-6514FC3F176B",
        content: "봄 한철 격정을 인내한 나의 사랑은 지고 있다"
    ),
    Notification(
        notificationId: UUID(),
        senderId: "wR6SLGIakuVZtYl6jCjge0JRPsF2",
        receiverIds: ["MyYdLZPoWjb3D8TvWfQLfx1wYf82"],
        feedbackId: "07F0C9A3-2C33-46C7-94C6-CCFAE7B75CF7",
        replyId: nil,
        createdAt: Date.now,
        videoId: "EB6EB151-3DCC-44E7-9A73-6514FC3F176B",
        content: "분분한 낙화. 결별이 이룩하는 축복에 싸여 지금은 가야 할 때"
    ),
    Notification(
        notificationId: UUID(),
        senderId: "39GGxwlYpWe8bamRae2Cfj168F63",
        receiverIds: ["MyYdLZPoWjb3D8TvWfQLfx1wYf82"],
        feedbackId: "07F0C9A3-2C33-46C7-94C6-CCFAE7B75CF7",
        replyId: nil,
        createdAt: Date.now,
        videoId: "EB6EB151-3DCC-44E7-9A73-6514FC3F176B",
        content: "무성한 녹음과 그리고 머지않아 열매 맺는 가을을 향하여 나의 청춘은 꽃답게 죽는다."
    ),
    Notification(
        notificationId: UUID(),
        senderId: "HqU0UNmrS5UBhxKZjhz4wqku4XB3",
        receiverIds: ["MyYdLZPoWjb3D8TvWfQLfx1wYf82"],
        feedbackId: "07F0C9A3-2C33-46C7-94C6-CCFAE7B75CF7",
        replyId: nil,
        createdAt: Date.now,
        videoId: "EB6EB151-3DCC-44E7-9A73-6514FC3F176B",
        content: "헤어지자 섬세한 손길을 흔들며 하롱하롱 꽃잎이 지는 어느 날."
    ),
    Notification(
        notificationId: UUID(),
        senderId: "HqU0UNmrS5UBhxKZjhz4wqku4XB3",
        receiverIds: ["MyYdLZPoWjb3D8TvWfQLfx1wYf82"],
        feedbackId: "07F0C9A3-2C33-46C7-94C6-CCFAE7B75CF7",
        replyId: nil,
        createdAt: Date.now,
        videoId: "EB6EB151-3DCC-44E7-9A73-6514FC3F176B",
        content: "나의 사랑, 나의 결별 샘터에 물 고이듯 성숙하는 내 영혼의 슬픈 눈.."
    ),
    Notification(
        notificationId: UUID(),
        senderId: "wR6SLGIakuVZtYl6jCjge0JRPsF2",
        receiverIds: ["MyYdLZPoWjb3D8TvWfQLfx1wYf82"],
        feedbackId: "07F0C9A3-2C33-46C7-94C6-CCFAE7B75CF7",
        replyId: nil,
        createdAt: Date.now,
        videoId: "EB6EB151-3DCC-44E7-9A73-6514FC3F176B",
        content: "죽는 날까지 하늘을 우러러"
    ),
    Notification(
        notificationId: UUID(),
        senderId: "39GGxwlYpWe8bamRae2Cfj168F63",
        receiverIds: ["MyYdLZPoWjb3D8TvWfQLfx1wYf82"],
        feedbackId: "07F0C9A3-2C33-46C7-94C6-CCFAE7B75CF7",
        replyId: nil,
        createdAt: Date.now,
        videoId: "EB6EB151-3DCC-44E7-9A73-6514FC3F176B",
        content: "한 점 부끄럼이 없기를,"
    ),
    Notification(
        notificationId: UUID(),
        senderId: "HqU0UNmrS5UBhxKZjhz4wqku4XB3",
        receiverIds: ["MyYdLZPoWjb3D8TvWfQLfx1wYf82"],
        feedbackId: "UUID20",
        replyId: nil,
        createdAt: Date.now,
        videoId: "EB6EB151-3DCC-44E7-9A73-6514FC3F176B",
        content: "잎새에 이는 바람에도"
    ),
    
    //MARK: - 30개
    Notification(
        notificationId: UUID(),
        senderId: "HqU0UNmrS5UBhxKZjhz4wqku4XB3",
        receiverIds: ["MyYdLZPoWjb3D8TvWfQLfx1wYf82"],
        feedbackId: "07F0C9A3-2C33-46C7-94C6-CCFAE7B75CF7",
        replyId: nil,
        createdAt: Date.now,
        videoId: "EB6EB151-3DCC-44E7-9A73-6514FC3F176B",
        content: "Lorem Ipsum..."
    ),
    Notification(
        notificationId: UUID(),
        senderId: "39GGxwlYpWe8bamRae2Cfj168F63",
        receiverIds: ["MyYdLZPoWjb3D8TvWfQLfx1wYf82"],
        feedbackId: "07F0C9A3-2C33-46C7-94C6-CCFAE7B75CF7",
        replyId: nil,
        createdAt: Calendar.current.date(byAdding: .day, value: -3, to: Date())!, // 72시간 전
        videoId: "EB6EB151-3DCC-44E7-9A73-6514FC3F176B",
        content: "우리 살아가는 일 속에"
    ),
    Notification(
        notificationId: UUID(),
        senderId: "wR6SLGIakuVZtYl6jCjge0JRPsF2",
        receiverIds: ["MyYdLZPoWjb3D8TvWfQLfx1wYf82"],
        feedbackId: "07F0C9A3-2C33-46C7-94C6-CCFAE7B75CF7",
        replyId: nil,
        createdAt: Date.now,
        videoId: "EB6EB151-3DCC-44E7-9A73-6514FC3F176B",
        content: "파도 치는 날 바람 부는 날이 어디 한두 번이랴."
    ),
    Notification(
        notificationId: UUID(),
        senderId: "39GGxwlYpWe8bamRae2Cfj168F63",
        receiverIds: ["MyYdLZPoWjb3D8TvWfQLfx1wYf82"],
        feedbackId: "07F0C9A3-2C33-46C7-94C6-CCFAE7B75CF7",
        replyId: nil,
        createdAt: Date.now,
        videoId: "EB6EB151-3DCC-44E7-9A73-6514FC3F176B",
        content: "그런 날은 조용히 닻을 내리고 오늘 일을 잠시라도 낮은 곳에 묻어두어야 한다. 우리 사랑하는 일 또한 그 같아서 파도치는 날 바람 부는 날은 높은 파도를 타지 않고 낮게 낮게 밀물져야 한다"
    ),
    Notification(
        notificationId: UUID(),
        senderId: "HqU0UNmrS5UBhxKZjhz4wqku4XB3",
        receiverIds: ["MyYdLZPoWjb3D8TvWfQLfx1wYf82"],
        feedbackId: "07F0C9A3-2C33-46C7-94C6-CCFAE7B75CF7",
        replyId: nil,
        createdAt: Date.now,
        videoId: "EB6EB151-3DCC-44E7-9A73-6514FC3F176B",
        content: "사랑하는 이여 상처받지 않은 사랑이 어디 있으랴"
    ),
    Notification(
        notificationId: UUID(),
        senderId: "HqU0UNmrS5UBhxKZjhz4wqku4XB3",
        receiverIds: ["MyYdLZPoWjb3D8TvWfQLfx1wYf82"],
        feedbackId: "07F0C9A3-2C33-46C7-94C6-CCFAE7B75CF7",
        replyId: nil,
        createdAt: Date.now,
        videoId: "EB6EB151-3DCC-44E7-9A73-6514FC3F176B",
        content: "추운 겨울 다 지내고"
    ),
    Notification(
        notificationId: UUID(),
        senderId: "wR6SLGIakuVZtYl6jCjge0JRPsF2",
        receiverIds: ["MyYdLZPoWjb3D8TvWfQLfx1wYf82"],
        feedbackId: "07F0C9A3-2C33-46C7-94C6-CCFAE7B75CF7",
        replyId: nil,
        createdAt: Date.now,
        videoId: "EB6EB151-3DCC-44E7-9A73-6514FC3F176B",
        content: "꽃 필 차례가"
    ),
    Notification(
        notificationId: UUID(),
        senderId: "39GGxwlYpWe8bamRae2Cfj168F63",
        receiverIds: ["MyYdLZPoWjb3D8TvWfQLfx1wYf82"],
        feedbackId: "07F0C9A3-2C33-46C7-94C6-CCFAE7B75CF7",
        replyId: nil,
        createdAt: Date.now,
        videoId: "EB6EB151-3DCC-44E7-9A73-6514FC3F176B",
        content: "바로 그대 앞에 있다.]"
    ),
    Notification(
        notificationId: UUID(),
        senderId: "HqU0UNmrS5UBhxKZjhz4wqku4XB3",
        receiverIds: ["MyYdLZPoWjb3D8TvWfQLfx1wYf82"],
        feedbackId: "07F0C9A3-2C33-46C7-94C6-CCFAE7B75CF7",
        replyId: nil,
        createdAt: Date.now,
        videoId: "EB6EB151-3DCC-44E7-9A73-6514FC3F176B",
        content: "동해물과 백두산이 마르고 닳도록 하느님이 보우하사 우리나라 만세"
    ),
    Notification(
        notificationId: UUID(),
        senderId: "HqU0UNmrS5UBhxKZjhz4wqku4XB3",
        receiverIds: ["MyYdLZPoWjb3D8TvWfQLfx1wYf82"],
        feedbackId: "07F0C9A3-2C33-46C7-94C6-CCFAE7B75CF7",
        replyId: nil,
        createdAt: Date.now,
        videoId: "EB6EB151-3DCC-44E7-9A73-6514FC3F176B",
        content: "🇰🇷🇰🇵 대한사람 대한으로 길이 보전하세!]"
    )
]
