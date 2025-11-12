//
//  MailView.swift
//  DanceMachine
//
//  Created by Paidion on 11/12/25.
//

import SwiftUI
import MessageUI

struct MailView: UIViewControllerRepresentable {
  @Environment(\.dismiss) var dismiss
  @Binding var needToCreateReport: Bool
  
  let subject: String
  let recipients: [String] = ["ask.diract@gmail.com"]
  let body: String
  
  func makeUIViewController(context: Context) -> MFMailComposeViewController {
    let vc = MFMailComposeViewController()
    vc.mailComposeDelegate = context.coordinator
    vc.setSubject(subject)
    vc.setToRecipients(recipients)
    vc.setMessageBody(body, isHTML: false)
    return vc
  }
  
  func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
  
  func makeCoordinator() -> Coordinator {
    Coordinator(
      needToCreateReport: $needToCreateReport,
      dismiss: dismiss
    )
  }
  
  class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
    var needToCreateReport: Binding<Bool>
    var dismiss: DismissAction
    
    init(needToCreateReport: Binding<Bool>, dismiss: DismissAction) {
      self.needToCreateReport = needToCreateReport
      self.dismiss = dismiss
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult,
                               error: Error?) {
      if result == .sent {
          self.needToCreateReport.wrappedValue = true
      }
      dismiss()
    }
  }
}
