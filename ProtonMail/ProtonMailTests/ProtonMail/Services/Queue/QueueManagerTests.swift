//
//  QueueManagerTests.swift
//  Proton Mail
//
//
//  Copyright (c) 2021 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import XCTest
@testable import ProtonMail

class QueueManagerTests: XCTestCase {

    private var sut: QueueManager!
    private var messageQueue: PMPersistentQueue!
    private var miscQueue: PMPersistentQueue!
    private var dataSaverSpy: MockDiskSaver!
    private var notificationName: Notification.Name!
    private var handlerMock: MockQueueHandler!
    private var loadedTaskUUIDs: [UUID]!
    private var miscTaskUUIDs: [UUID]!
    private var backupExcluderDumb: MockBackupExcluder!

    override func setUp() {
        super.setUp()

        backupExcluderDumb = MockBackupExcluder()
        dataSaverSpy = MockDiskSaver()
        messageQueue = PMPersistentQueue(queueName: "messageQueueTests",
                                         dataSaver: dataSaverSpy,
                                         backupExcluder: backupExcluderDumb)
        miscQueue = PMPersistentQueue(queueName: "miscQueueTests",
                                      dataSaver: dataSaverSpy,
                                      backupExcluder: backupExcluderDumb)
        sut = QueueManager(messageQueue: messageQueue, miscQueue: miscQueue)
        handlerMock = MockQueueHandler(userID: "userID1")
        sut.registerHandler(handlerMock)
        notificationName = Notification.Name("queueIsEmpty")
        loadedTaskUUIDs = []
        miscTaskUUIDs = []
    }

    override func tearDown() {
        super.tearDown()

        dataSaverSpy = nil
        messageQueue = nil
        miscQueue = nil
        sut = nil
        handlerMock = nil
        notificationName = nil
        loadedTaskUUIDs = nil
        miscTaskUUIDs = nil
    }

    func testGetNewTask() {
        let newTask = QueueManager.Task(messageID: "", action: .emptySpam, userID: "", dependencyIDs: [], isConversation: false)
        XCTAssertEqual(newTask.messageID, "")
        XCTAssertEqual(newTask.action, .emptySpam)
        XCTAssertEqual(newTask.userID, "")
        XCTAssertEqual(newTask.dependencyIDs.count, 0)
        XCTAssertFalse(newTask.isConversation)
    }
    
    func testAddUnknownTask() {
        let task = QueueManager.Task(messageID: "messageID", action: .emptySpam, userID: "", dependencyIDs: [], isConversation: false)
        let e = expectation(description: "Closure is called")

        sut.addTask(task) { result in
            XCTAssertFalse(result)
            e.fulfill()
        }

        waitForExpectations(timeout: 1)
    }
    
    func testAddTask() {
        let task = QueueManager.Task(messageID: "messageID", action: .emptySpam, userID: "userID1", dependencyIDs: [], isConversation: false)
        self.loadedTaskUUIDs.append(task.uuid)
        let e = expectation(description: "Closure is called")

        sut.addTask(task, autoExecute: false) { result in
            XCTAssertTrue(result)
            e.fulfill()
        }
        waitForExpectations(timeout: 1)
        
        let finish = expectation(description: "Notification Raised")
        sut.backgroundFetch(remainingTime: {
            999.0
        }) {
            finish.fulfill()
        }
        
        wait(for: [finish], timeout: 5.0)
        XCTAssertEqual(self.handlerMock.handleCount, self.loadedTaskUUIDs.count)
        checkExcuteSequence()
    }
    
    func testAddEmptyTask() {
        let e = expectation(description: "Closure is called")
        let task = QueueManager.Task(messageID: "", action: .emptySpam, userID: "", dependencyIDs: [], isConversation: false)

        sut.addTask(task) { result in
            XCTAssertFalse(result)
            e.fulfill()
        }
        waitForExpectations(timeout: 1)

        XCTAssertEqual(messageQueue.count, 0)
    }
    
    func testSignout() {
        loadTestData()
        let e = expectation(description: "Closure is called")
        let task = QueueManager.Task(messageID: "", action: .signout, userID: "userID1", dependencyIDs: [], isConversation: false)
        sut.addTask(task, autoExecute: false, completion: { result in
            e.fulfill()
        })
        waitForExpectations(timeout: 1)
        
        XCTAssertEqual(self.messageQueue.count, 1)
        XCTAssertEqual(self.miscQueue.count, 1)
        
        let finish = expectation(description: "Notification Raised")
        sut.backgroundFetch(remainingTime: {
            999.0
        }) {
            finish.fulfill()
        }
        
        wait(for: [finish], timeout: 5.0)
        XCTAssertEqual(self.handlerMock.handleCount, 1)
    }
    
    func testSignout_signin() {
        loadTestData()
        let task = QueueManager.Task(messageID: "", action: .signout, userID: "userID1", dependencyIDs: [], isConversation: false)
        _ = addTaskToSUT(task: task, autoExecute: false)
        
        XCTAssertEqual(self.messageQueue.count, 1)
        XCTAssertEqual(self.miscQueue.count, 1)
        
        let signin = QueueManager.Task(messageID: "", action: .signin, userID: "userID1", dependencyIDs: [], isConversation: false)
        _ = addTaskToSUT(task: signin, autoExecute: false)
        
        XCTAssertEqual(self.messageQueue.count, 0)
        XCTAssertEqual(self.miscQueue.count, 0)
    }
    
    func testDependency() {
        loadTestData()
        let msgTasks = self.messageQueue.queueArray()
            .compactMap({ $0 as? [String: Any]})
            .compactMap({ $0["object"] as? QueueManager.Task })
        // The related tasks should add dependencies
        XCTAssertEqual(msgTasks[0].dependencyIDs, [])
        XCTAssertEqual(msgTasks[1].dependencyIDs, [msgTasks[0].uuid])
        
        let miscTasks = self.miscQueue.queueArray()
            .compactMap({ $0 as? [String: Any]})
            .compactMap({ $0["object"] as? QueueManager.Task })
        XCTAssertEqual(miscTasks[0].dependencyIDs, [])
        XCTAssertEqual(miscTasks[1].dependencyIDs, [])
        
        let finish = expectation(description: "Notification Raised")
        sut.backgroundFetch(remainingTime: {
            999.0
        }) {
            finish.fulfill()
        }
        
        wait(for: [finish], timeout: 5.0)
        XCTAssert(self.messageQueue.count == 0)
        XCTAssert(self.miscQueue.count == 0)
    }
    
    func testDependencyFailed() {
        let task1 = QueueManager.Task(messageID: "messageID1", action: .send(messageObjectID: "", deliveryTime: nil), userID: "userID1", dependencyIDs: [UUID()], isConversation: false)
        _ = self.messageQueue.add(task1.uuid, object: task1)
        
        let finish = expectation(description: "Notification Raised")
        sut.backgroundFetch(remainingTime: {
            999.0
        }) {
            finish.fulfill()
        }
        
        wait(for: [finish], timeout: 5.0)
        XCTAssertEqual(self.handlerMock.handleCount, 0)
    }
    
    func testRemoveAllTasks() {
        loadTestData(autoExecute: false)
        
        let finish = expectation(description: "Notification Raised")
        sut.removeAllTasks(of: "messageID3", removalCondition: { action in
            switch action {
            case .send, .saveDraft:
                return true
            default:
                return false
            }
        }, completeHandler: {
            finish.fulfill()
        })
        
        wait(for: [finish], timeout: 5.0)
        XCTAssertEqual(self.miscQueue.count, 2)
        XCTAssertEqual(self.messageQueue.count, 0)
    }
    
    func testRemoveAll() {
        loadTestData()
        
        XCTAssertEqual(messageQueue.count, 2)
        XCTAssertEqual(miscQueue.count, 2)
        
        let finish = expectation(description: "Notification Raised")
        Task {
            await sut.clearAll()
            finish.fulfill()
        }
        
        wait(for: [finish], timeout: 5.0)
        XCTAssertEqual(messageQueue.count, 0)
        XCTAssertEqual(miscQueue.count, 0)
    }
    
    func testDequeueIfNeeded() {
        loadTestData()
        
        let finish = expectation(description: "Notification Raised")
        sut.backgroundFetch(remainingTime: {
            999.0
        }) {
            finish.fulfill()
        }
        
        wait(for: [finish], timeout: 5.0)
        XCTAssertEqual(self.handlerMock.handleCount, self.loadedTaskUUIDs.count+self.miscTaskUUIDs.count)
        checkExcuteSequence()
    }
    
    func testPauseDequeueIfNeeded() {
        loadTestData()
        let pause = expectation(description: "Pause")
        sut.backgroundFetch {
            0
        } notify: {
            pause.fulfill()
        }

        wait(for: [pause], timeout: 10.0)
    }
    
    func testCallConcurrentCallOfDequeueIfNeeded() {
        loadTestData()

        let finish = expectation(description: "Finish")
        sut.backgroundFetch(remainingTime: {
            999.0
        }) {
            finish.fulfill()
        }

//        DispatchQueue.concurrentPerform(iterations: 20) { (_) in
//            self.sut.backgroundFetch(allowedTime: time) {
//                finish.fulfill()
//            }
//        }

        wait(for: [finish], timeout: 5.0)
        XCTAssertEqual(self.handlerMock.handleCount, self.loadedTaskUUIDs.count+self.miscTaskUUIDs.count)

        checkExcuteSequence()
    }
    
    func testLegacyObjectAndCurrentTaskDequeueIfNeeded() {
        loadTestData()
        loadTestData(autoExecute: true)

        let finish = expectation(description: "Notification Raised")
        sut.backgroundFetch(remainingTime: {
            999.0
        }) {
            finish.fulfill()
        }
        
        wait(for: [finish], timeout: 5.0)
        XCTAssertEqual(self.handlerMock.handleCount, self.loadedTaskUUIDs.count + self.miscTaskUUIDs.count)
        checkExcuteSequence()
    }
    
    func testIsAnyQueuedMessage() {
        loadTestData()
        
        XCTAssertTrue(sut.isAnyQueuedMessage(of: "userID1"))
    }
    
    func testIsAnyQueuedMessageWithUnknownUserID() {
        XCTAssertFalse(sut.isAnyQueuedMessage(of: "No ID"))
        
        loadTestData()
        
        XCTAssertFalse(sut.isAnyQueuedMessage(of: "No ID"))
    }
    
    func testDeleteAllQueuedMessage() {
        loadTestData()
        
        let finish = expectation(description: "Notification Raised")
        sut.deleteAllQueuedMessage(of: "userID1") {
            finish.fulfill()
        }
        
        wait(for: [finish], timeout: 5.0)
        XCTAssertEqual(messageQueue.count, 0)
        XCTAssertEqual(miscQueue.count, 0)
    }
    
    func testDeleteAllQueuedMessageWithUnknownUserID() {
        let task = QueueManager.Task(messageID: "messageID1", action: .delete(currentLabelID: nil, itemIDs: []), userID: "No ID", dependencyIDs: [], isConversation: false)
        XCTAssertTrue(addTaskToSUT(task: task, autoExecute: false))
        
        loadTestData()
        
        XCTAssertEqual(messageQueue.count, 2)
        XCTAssertEqual(miscQueue.count, 3)
        
        let finish = expectation(description: "Notification Raised")
        sut.deleteAllQueuedMessage(of: "No ID") {
            finish.fulfill()
        }
        
        wait(for: [finish], timeout: 5.0)
        XCTAssertEqual(messageQueue.count, 2)
        XCTAssertEqual(miscQueue.count, 2)
    }
    
    func testQueuedMessageIds() {
        loadTestData()
        
        let ids = sut.queuedMessageIds()
        XCTAssertEqual(ids.count, 1)
        XCTAssertTrue(ids.contains("messageID3"))
    }
    
    func testConnectIssue1() {
        let task = QueueManager.Task(messageID: "messageID", action: .read(itemIDs: [], objectIDs: []), userID: "userID1", dependencyIDs: [], isConversation: false)
        self.miscTaskUUIDs.append(task.uuid)
        self.handlerMock.setResult(to: .connectionIssue)
        XCTAssertTrue(addTaskToSUT(task: task, autoExecute: true))

        XCTAssertEqual(self.handlerMock.handleCount, self.miscTaskUUIDs.count)
        checkExcuteSequence()
        XCTAssertEqual(self.miscQueue.count, 1)
    }
    
    func testConnectIssue2() {
        let task = QueueManager.Task(messageID: "messageID", action: .signout, userID: "userID1", dependencyIDs: [], isConversation: false)
        self.miscTaskUUIDs.append(task.uuid)
        self.handlerMock.setResult(to: .connectionIssue)
        XCTAssertTrue(addTaskToSUT(task: task, autoExecute: true))

        XCTAssertEqual(self.handlerMock.handleCount, self.miscTaskUUIDs.count)
        checkExcuteSequence()
        wait(self.miscQueue.count == 0)
    }
    
    func testRemoveRelated() {
        self.handlerMock.setResult(to: .removeRelated)
        let task1 = QueueManager.Task(messageID: "messageID3", action: .saveDraft(messageObjectID: ""), userID: "userID1", dependencyIDs: [], isConversation: false)
        self.loadedTaskUUIDs.append(task1.uuid)
        XCTAssertTrue(addTaskToSUT(task: task1, autoExecute: false))
        
        let task2 = QueueManager.Task(messageID: "messageID3", action: .uploadAtt(attachmentObjectID: ""), userID: "userID1", dependencyIDs: [], isConversation: false)
        self.loadedTaskUUIDs.append(task2.uuid)
        XCTAssertTrue(addTaskToSUT(task: task2, autoExecute: false))
        
        // will be removed
        let task3 = QueueManager.Task(messageID: "messageID3", action: .saveDraft(messageObjectID: ""), userID: "userID1", dependencyIDs: [], isConversation: false)
        XCTAssertTrue(addTaskToSUT(task: task3, autoExecute: false))
        
        let finish = expectation(description: "Notification Raised")
        sut.backgroundFetch(remainingTime: {
            999.0
        }) {
            finish.fulfill()
        }
        
        wait(for: [finish], timeout: 5.0)
        XCTAssertEqual(self.handlerMock.handleCount, 2)
        checkExcuteSequence()
    }
    
    func testCheckReadQueue() {
        self.handlerMock.setResult(to: .checkReadQueue)
        let task1 = QueueManager.Task(messageID: "messageID3", action: .saveDraft(messageObjectID: ""), userID: "userID1", dependencyIDs: [], isConversation: false)
        self.loadedTaskUUIDs.append(task1.uuid)
        XCTAssertTrue(addTaskToSUT(task: task1, autoExecute: false))
        
        let task2 = QueueManager.Task(messageID: "messageID3", action: .uploadAtt(attachmentObjectID: ""), userID: "userID1", dependencyIDs: [], isConversation: false)
        XCTAssertTrue(addTaskToSUT(task: task2, autoExecute: false))
        
        let task3 = QueueManager.Task(messageID: "messageID3", action: .saveDraft(messageObjectID: ""), userID: "userID1", dependencyIDs: [], isConversation: false)
        XCTAssertTrue(addTaskToSUT(task: task3, autoExecute: false))
        
        let task4 = QueueManager.Task(messageID: "messageID3", action: .read(itemIDs: [], objectIDs: []), userID: "userID1", dependencyIDs: [], isConversation: false)
        XCTAssertTrue(addTaskToSUT(task: task4, autoExecute: false))
        
        let finish = expectation(description: "Notification Raised")
        self.sut.queue {
            finish.fulfill()
        }
        wait(for: [finish], timeout: 5.0)
        XCTAssert(self.handlerMock.handleCount == 3)
    }

    func testMessageIDsOfTasksFetchesMessageTasksOnly() {
        loadTestData()

        let messageIDs = sut.messageIDsOfTasks { action in
            switch action {
            case .deleteLabel:
                // deleteLabel is not a message task, this `return true` is intentional
                return true
            case .send:
                return true
            default:
                return false
            }
        }

        XCTAssertEqual(messageIDs, ["messageID3"])
    }
}

extension QueueManagerTests {
    private func checkExcuteSequence() {
        XCTAssertNotEqual(self.handlerMock.handledTasks.count, 0)
        XCTAssertEqual(self.handlerMock.handleCount, self.handlerMock.handledTasks.count)
        var copyMiscIds: [UUID] = self.miscTaskUUIDs
        var copyMessageIds: [UUID] = self.loadedTaskUUIDs
        let tasks = self.handlerMock.handledTasks
        for task in tasks {
            if copyMiscIds.count > 0 && copyMiscIds[0] == task.uuid {
                _ = copyMiscIds.remove(at: 0)
                continue
            }
            
            if copyMessageIds.count > 0 && copyMessageIds[0] == task.uuid {
                _ = copyMessageIds.remove(at: 0)
                continue
            }
            XCTAssert(false)
        }
    }
    
    private func loadTestData(autoExecute: Bool = false) {
        let task = QueueManager.Task(messageID: "messageID1", action: .deleteLabel(labelID: ""), userID: "userID1", dependencyIDs: [], isConversation: false)
        self.miscTaskUUIDs.append(task.uuid)
        
        XCTAssertTrue(addTaskToSUT(task: task, autoExecute: autoExecute))
        
        let task2 = QueueManager.Task(messageID: "messageID2", action: .empty(currentLabelID: ""), userID: "userID1", dependencyIDs: [], isConversation: false)
        self.miscTaskUUIDs.append(task2.uuid)
        
        XCTAssertTrue(addTaskToSUT(task: task2, autoExecute: autoExecute))
        
        let task3 = QueueManager.Task(messageID: "messageID3", action: .send(messageObjectID: "", deliveryTime: nil), userID: "userID1", dependencyIDs: [], isConversation: false)
        self.loadedTaskUUIDs.append(task3.uuid)
        
        XCTAssertTrue(addTaskToSUT(task: task3, autoExecute: autoExecute))
        
        let task4 = QueueManager.Task(messageID: "messageID3", action: .saveDraft(messageObjectID: ""), userID: "userID1", dependencyIDs: [], isConversation: false)
        self.loadedTaskUUIDs.append(task4.uuid)
        
        XCTAssertTrue(addTaskToSUT(task: task4, autoExecute: autoExecute))
    }

    private func addTaskToSUT(task: QueueManager.Task, autoExecute: Bool) -> Bool {
        var result = false
        let e = expectation(description: "Closure is called")
        sut.addTask(task, autoExecute: autoExecute) { value in
            result = value
            e.fulfill()
        }
        waitForExpectations(timeout: 1)
        return result
    }
}
