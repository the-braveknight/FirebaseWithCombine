//
//  File.swift
//  File
//
//  Created by Zaid Rahhawi on 8/11/21.
//

import Foundation
import Combine
import FirebaseFirestore

public struct FirestoreDocumentPublisher : Publisher {
    public typealias Failure = Error
    public typealias Output = DocumentSnapshot
    
    let documentReference: DocumentReference
    
    public func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
        //
        let subscription = FirestoreDocumentSubscriber(subscriber: subscriber, documentReference: documentReference)
        subscriber.receive(subscription: subscription)
    }
}

extension FirestoreDocumentPublisher {
    class FirestoreDocumentSubscriber<S: Subscriber> : Subscription where S.Input == Output, S.Failure == Failure {
        private var subscriber: S?
        private let documentReference: DocumentReference
        private var listener: ListenerRegistration?
        
        init(subscriber: S, documentReference: DocumentReference) {
            self.subscriber = subscriber
            self.documentReference = documentReference

            self.listener = documentReference.addSnapshotListener { snapshot, error in
                if let snapshot = snapshot {
                    _ = subscriber.receive(snapshot)
                } else if let error = error {
                    subscriber.receive(completion: .failure(error))
                }
            }
        }

        func cancel() {
            subscriber = nil
            listener?.remove()
        }
        
        func request(_ demand: Subscribers.Demand) {
            //
        
        }
    }
}

public extension DocumentReference {
    public func listen() -> FirestoreDocumentPublisher {
        .init(documentReference: self)
    }
    
    public func getSnapshot() -> Future<DocumentSnapshot, Error> {
        Future { promise in
            self.getDocument { snapshot, error in
                if let snapshot = snapshot {
                    promise(.success(snapshot))
                } else if let error = error {
                    promise(.failure(error))
                }
            }
        }
    }
}
