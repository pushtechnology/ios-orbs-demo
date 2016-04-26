//  Native Orbs Demo for iOS
//
//  Copyright (C) 2016 Push Technology Ltd.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

import Foundation
import Diffusion

// The Orbs Demo's root topic path.
let rootTopicPath = "OrbsDemo";

// Topic selector expression for the Orbs Demo's root topic and descendants.
let topicSelector = "*" + rootTopicPath + "//";

// The string preceeding the Orb key in the full topic path.
let topicPathPrefix = rootTopicPath + "/";

class OrbsClient: NSObject, PTDiffusionTopicStreamDelegate {
    private var session: PTDiffusionSession?
    var listener: OrbListener?

    func connect(url: NSURL) {
        NSLog("Connecting...")
        PTDiffusionSession.openWithURL(url) { (session, error) -> Void in
            if let connectedSession = session {
                NSLog("Connected.")

                // Maintain a strong reference to the session.
                self.session = connectedSession

                // Register self as the topic stream handler for the Orbs Demo tree.
                let localSelector = PTDiffusionTopicSelector(expression: topicSelector)
                connectedSession.topics.addTopicStreamWithSelector(localSelector, delegate: self)

                // Subscribe to the Orbs demo topic tree.
                NSLog("Subscribing...")
                connectedSession.topics.subscribeWithTopicSelectorExpression(topicSelector) { (error) -> Void in
                    if (error != nil) {
                        self.fail(error!)
                        return
                    }

                    NSLog("Subscribed.")
                }
            } else {
                self.fail(error!)
            }
        }
    }

    func diffusionStream(stream: PTDiffusionStream, didUpdateTopicPath topicPath: String, content: PTDiffusionContent, context: PTDiffusionUpdateContext) {
        if let key = OrbKey(topicPath: topicPath.substringFromIndex(topicPathPrefix.endIndex)) {
            let state = OrbState(csv: String(data: content.data, encoding: NSUTF8StringEncoding)!)
            listener?.orbDidUpdate(key, state: state)
        }
    }

    func diffusionStream(stream: PTDiffusionStream, didUnsubscribeFromTopicPath topicPath: String, reason: PTDiffusionTopicUnsubscriptionReason) {
        if let key = OrbKey(topicPath: topicPath.substringFromIndex(topicPathPrefix.endIndex)) {
            listener?.orbDidDisappear(key)
        }
    }

    private func keyForTopicPath(topicPath: String) -> String {
        return topicPath.substringFromIndex(topicPathPrefix.endIndex)
    }

    private func fail(error: NSError) {
        NSLog("Failed: %@", error)
    }
}