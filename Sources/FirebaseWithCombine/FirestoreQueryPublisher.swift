//
//  File.swift
//  File
//
//  Created by Zaid Rahhawi on 8/11/21.
//

import Foundation
import Combine
import FirebaseFirestore

struct FirestoreQueryPublisher: Publisher {
    typealias Failure = Error
    typealias Output = QuerySnapshot

    private let query: Query
    
    init(query: Query) {
        self.query = query
    }

    func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
        let subscription = FirestoreQuerySubscriber(subscriber: subscriber, query: query)
        subscriber.receive(subscription: subscription)
    }
}

extension FirestoreQueryPublisher {
    class FirestoreQuerySubscriber<S : Subscriber> : Subscription where S.Input == Output, S.Failure == Failure {
        private var subscriber: S?
        private let query: Query
        private var listener: ListenerRegistration?

        init(subscriber: S, query: Query) {
            self.subscriber = subscriber
            self.query = query

            self.listener = query.addSnapshotListener { snapshot, error in
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
            
        }
    }
}

public extension Query {
    public func listen() -> FirestoreQueryPublisher {
        .init(query: self)
    }
    
    public func getSnapshot() -> Future<QuerySnapshot, Error> {
        Future { promise in
            self.getDocuments { snapshot, error in
                if let snapshot = snapshot {
                    promise(.success(snapshot))
                } else if let error = error {
                    promise(.failure(error))
                }
            }
        }
    }
}
