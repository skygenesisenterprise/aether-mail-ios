enum ConversationNavigationAction {
    case reply(
        message: MessageEntity,
        remoteContentPolicy: WebContents.RemoteContentPolicy,
        embeddedContentPolicy: WebContents.EmbeddedContentPolicy
    )
    case replyAll(
        message: MessageEntity,
        remoteContentPolicy: WebContents.RemoteContentPolicy,
        embeddedContentPolicy: WebContents.EmbeddedContentPolicy
    )
    case forward(
        message: MessageEntity,
        remoteContentPolicy: WebContents.RemoteContentPolicy,
        embeddedContentPolicy: WebContents.EmbeddedContentPolicy
    )
    case draft(message: MessageEntity)
    case addContact(contact: ContactVO)
    case composeTo(contact: ContactVO)
    case mailToUrl(url: URL)
    case attachmentList(inlineCIDs: [String]?, attachments: [AttachmentInfo])
    case viewHeaders(url: URL)
    case viewHTML(url: URL)
    case viewCypher(url: URL)
    case url(url: URL)
    case inAppSafari(url: URL)
    case addNewLabel
    case addNewFolder
    case toolbarCustomization(currentActions: [MessageViewActionSheetAction],
                              allActions: [MessageViewActionSheetAction])
    case toolbarSettingView
}
