//
//  NotificationWithConcurrency.swift
//
//  Created by Itsuki on 2025/12/14.
//

import SwiftUI

private extension NotificationCenter.MessageIdentifier where Self == NotificationCenter.BaseMessageIdentifier<CountDidUpdate> {
    static var countDidUpdate: Self { .init() }
}

private extension NotificationCenter.MessageIdentifier where Self == NotificationCenter.BaseMessageIdentifier<CountDidUpdateBackground> {
    static var countDidUpdateBackground: Self { .init() }
}


// MainActorMessage: delivered on main thread
private struct CountDidUpdate: NotificationCenter.MainActorMessage {
    // Sender of the notification Matches the `object` in post()
    // For example, if the notification is sent by a manager class, for example, CountManager,
    // then `typealias Subject = CountManager`
    typealias Subject = Never
    
    // Property to post
    // ie: those properties that we used to post in our userInfo payload.
    let count: Int
}

// AsyncMessage: delivered on arbitrary isolation
private struct CountDidUpdateBackground: NotificationCenter.AsyncMessage {
    typealias Subject = Never
    let count: Int
}


struct NotificationWithConcurrencyDemo: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 48) {
                PostNotificationView()
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(.secondary.opacity(0.5))
                    .frame(height: 4)
                
                ObserveNotificationView()
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.yellow.opacity(0.1))
            .navigationTitle("Notification 🤝 Swift 6")
        }
    }
}


private struct PostNotificationView: View {
    @State private var count: Int = 50
    
    var body: some View {
        VStack(spacing: 36) {
            Text("Post Notification On Count Change")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .center)

            
            HStack(spacing: 24) {
                button(action: {
                    count -= 1
                }, labelImage: "minus.square.fill")

                CountView(count: self.count)
                button(action: {
                    count += 1
                }, labelImage: "plus.square.fill")
            }
            .frame(maxWidth: .infinity)
            
        }
        .onChange(of: self.count, initial: true, {
            // new
            // main actor
            NotificationCenter.default.post(
                CountDidUpdate(count: self.count)
            )
            
            // arbitrary isolation
            NotificationCenter.default.post(
                CountDidUpdateBackground(count: self.count)
            )
        })
        
    }
    
    @ViewBuilder
    private func button(action: @escaping () -> Void, labelImage: String) -> some View {
        Button(action: action, label: {
            Image(systemName: labelImage)
                .font(.system(size: 40))
        })
        .buttonStyle(.borderless)
    }
}


private struct ObserveNotificationView: View {
    @State private var count: Int = 0
    @State var token: NotificationCenter.ObservationToken?

    var body: some View {
        VStack(spacing: 36) {
            Text("Observe Count Change Notification")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .center)
            
            CountView(count: self.count)
        }
        
        
        .onAppear {
            guard token == nil else { return }
            // main actor message
            self.token = NotificationCenter.default.addObserver(
                of: Never.self,
                for: .countDidUpdate
            ) { message in
                self.count = message.count
            }
        }
        .task {
            // async message
            for await message in NotificationCenter.default.messages(of: Never.self, for: .countDidUpdateBackground) {
                print("background count received: \(message.count)")
            }
        }
        .onDisappear {
            guard let token = self.token else { return }

            NotificationCenter.default.removeObserver(token)
        }

    }
}

private struct CountView: View {
    var count: Int
    var body: some View {
        Text("\(count)")
            .font(.system(size: 96))
            .fontWeight(.bold)
            .contentTransition(.numericText())
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .containerRelativeFrame(.horizontal, { length, axis in
                return axis == .horizontal ? length * 0.5 : length
            })

    }
}

