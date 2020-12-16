//
//  ViewController.swift
//  iOS14TTSBugDemo
//
//  Created by Wangchou Lu on R 2/12/07.
//

import UIKit
import Speech
import Promises

class ViewController: UIViewController {
    @IBOutlet weak var textview: UITextView!

    @IBAction func buttonClicked(_ sender: Any) {
        speakAll()
    }

    func speakAll() {
        let enTTS = TTS()
        let jaTTS = TTS()

        let enVoice = AVSpeechSynthesisVoice.speechVoices().filter { $0.language.contains("en") }[0]
        let jaVoice = AVSpeechSynthesisVoice.speechVoices().filter { $0.language.contains("ja") }[0]

        let lines: [(text: String, voice: AVSpeechSynthesisVoice)] = [
            (text: "pizza", voice: enVoice),
            (text: "鮭", voice: jaVoice),
            (text: "肉", voice: jaVoice),
            (text: "ice cream", voice: enVoice),
            (text: "鮭", voice: jaVoice),
            (text: "肉", voice: jaVoice),
            (text: "ice cream", voice: enVoice),
        ]

        var lineIndex = 0

        func sayNextLine() -> Promise<Void> {
            guard lineIndex < lines.count else {
                let promise = Promise<Void>.pending()
                promise.fulfill(())
                return promise
            }
            let line = lines[lineIndex]
            let tts = line.voice.language.contains("en") ? enTTS : jaTTS
            lineIndex += 1
            textview.text = "Speaking: \n\(line.text)\n by \(line.voice.identifier)"
            return tts.say(line.text, voice: line.voice).then {
                return sayNextLine()
            }
        }

        let startTime = NSDate().timeIntervalSince1970
        sayNextLine()
            .always {
                print(String(format: "finished time: %.2f", NSDate().timeIntervalSince1970 - startTime))
            }
    }
}

class TTS: NSObject, AVSpeechSynthesizerDelegate {
    var synthesizer = AVSpeechSynthesizer()
    var promise = Promise<Void>.pending()

    func say(_ text: String, voice: AVSpeechSynthesisVoice) -> Promise<Void> {
        promise = Promise<Void>.pending()
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        synthesizer.delegate = self
        synthesizer.speak(utterance)
        return promise
    }

    func speechSynthesizer(_: AVSpeechSynthesizer,
                           didFinish utterance: AVSpeechUtterance) {
        promise.fulfill(())
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        // do nothing...
        // but with this method will trigger en tts speak wrong text / skip text
    }
}
