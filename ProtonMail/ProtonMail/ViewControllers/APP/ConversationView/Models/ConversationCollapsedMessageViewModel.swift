import ProtonCoreUIFoundations
import UIKit

class ConversationCollapsedMessageViewModel {

    private var message: MessageEntity {
        didSet { reloadView?(self.model(customFolderLabels: cachedCustomFolderLabels)) }
    }

    private let weekStart: WeekStart

    var reloadView: ((ConversationMessageModel) -> Void)?

    let replacingEmailsMap: [String: EmailEntity]
    private var cachedCustomFolderLabels: [LabelEntity] = []

    private let dateFormatter: PMDateFormatter
    private let mailboxMessageCellHelper: MailboxMessageCellHelper
    private let contactGroups: [ContactGroupVO]

    init(
        message: MessageEntity,
        weekStart: WeekStart,
        replacingEmailsMap: [String: EmailEntity],
        contactGroups: [ContactGroupVO],
        mailboxMessageCellHelper: MailboxMessageCellHelper,
        dateFormatter: PMDateFormatter = .shared
    ) {
        self.message = message
        self.weekStart = weekStart
        self.replacingEmailsMap = replacingEmailsMap
        self.dateFormatter = dateFormatter
        self.contactGroups = contactGroups
        self.mailboxMessageCellHelper = mailboxMessageCellHelper
    }

    func model(customFolderLabels: [LabelEntity]) -> ConversationMessageModel {
        cachedCustomFolderLabels = customFolderLabels
        let tags = message.orderedLabel.map { label in
            TagUIModel(
                title: label.name,
                titleColor: .white,
                titleWeight: .semibold,
                icon: nil,
                tagColor: UIColor(hexString: label.color, alpha: 1.0)
            )
        }

        let senderRowComponents = mailboxMessageCellHelper.senderRowComponents(
            for: message,
            basedOn: replacingEmailsMap,
            groupContacts: contactGroups,
            shouldReplaceSenderWithRecipients: false
        )

        return ConversationMessageModel(
            messageLocation: message
                .getFolderMessageLocation(customFolderLabels: customFolderLabels)?.toMessageLocation,
            isCustomFolderLocation: message.isCustomFolder,
            initial: senderRowComponents.initials().apply(style: FontManager.body3RegularNorm),
            isRead: !message.unRead,
            sender: senderRowComponents,
            time: date(of: message, weekStart: weekStart),
            isForwarded: message.isForwarded,
            isReplied: message.isReplied,
            isRepliedToAll: message.isRepliedAll,
            isStarred: message.isStarred,
            hasAttachment: message.numAttachments > 0,
            tags: tags,
            expirationTag: message.createTagFromExpirationDate(),
            isDraft: message.isDraft,
            isScheduled: message.contains(location: .scheduled),
            isSent: message.isSent,
            isExpirationFrozen: message.flag.contains(.isExpirationTimeFrozen)
        )
    }

    func messageHasChanged(message: MessageEntity) {
        self.message = message
    }

    private func date(of message: MessageEntity, weekStart: WeekStart) -> String {
        guard let date = message.time else { return .empty }
        if message.isScheduledSend {
            return dateFormatter.stringForScheduledMsg(from: date, inListView: true)
        } else {
            return PMDateFormatter.shared.string(from: date, weekStart: weekStart)
        }
    }
}
