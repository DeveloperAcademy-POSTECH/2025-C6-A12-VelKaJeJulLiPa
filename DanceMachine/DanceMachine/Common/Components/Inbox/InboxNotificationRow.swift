import SwiftUI

struct InboxNotificationRow: View {
  let notification: InboxNotification
  
  var body: some View {
    VStack(spacing: 0) {
      content
      divider
    }
    .background(backgroundColor)
  }
}

// MARK: - Subviews
private extension InboxNotificationRow {
  var content: some View {
    HStack(spacing: 8) {
      notificationIcon
      notificationContent
    }
    .contentShape(Rectangle())
    .padding(.horizontal, 16)
    .padding(.vertical, 24)
  }
  
  var notificationIcon: some View {
    VStack(alignment: .leading) {
      iconImage
      Spacer()
    }
    .foregroundStyle(.secondaryStrong)
  }
  
  var iconImage: Image {
    Image(
      systemName: notification.type == .feedback
      ? "ellipsis.message"
      : "arrowshape.turn.up.left"
    )
  }
  
  var notificationContent: some View {
    VStack(alignment: .leading, spacing: 12) {
      header
      bodyContent
    }
  }
  
  var header: some View {
    HStack(spacing: 0) {
      Text(notification.videoTitle)
        .font(.footnoteMedium)
        .foregroundStyle(.labelAssitive)
        .multilineTextAlignment(.leading)
      
      Spacer()
      
      Text(notification.date.listTimeLabel())
        .font(.footnoteMedium)
        .foregroundStyle(.labelAssitive)
        .multilineTextAlignment(.leading)
    }
  }
  
  var bodyContent: some View {
    VStack(alignment: .leading, spacing: 8) {
      title
      message
    }
  }
  
  var title: some View {
    HStack(spacing: 0) {
      Text(josa(notification.senderName, "이/가") + " ")
        .font(.heading1SemiBold)
        .foregroundStyle(.labelStrong)
        .multilineTextAlignment(.leading)
      
      Text(
        notification.type == .feedback
        ? "피드백을 남겼어요"
        : "답글을 남겼어요"
      )
        .font(.heading1Medium)
        .foregroundStyle(.labelNormal)
        .multilineTextAlignment(.leading)
    }
  }
  
  var message: some View {
    Text(notification.content)
      .font(.body1Medium)
      .foregroundStyle(.labelNormal)
      .multilineTextAlignment(.leading)
  }
  
  var divider: some View {
    Divider()
      .foregroundStyle(.strokeNormal)
  }
  
  var backgroundColor: Color {
    notification.isRead ? .clear : .fillAlternative
  }
}
