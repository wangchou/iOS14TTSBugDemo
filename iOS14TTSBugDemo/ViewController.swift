//
//  ViewController.swift
//  iOS14TTSBugDemo
//
//  Created by Wangchou Lu on R 2/12/07.
//

import UIKit
import Speech

class ViewController: UIViewController {
    @IBOutlet weak var textview: UITextView!
    @IBAction func buttonClicked(_ sender: Any) {
        speakAll()
    }

    // Bug: The English tts will
    //    1. speak "ice cream" as rubbish text after some steps (iOS 14.2)
    //    2. skip speaking "ice cream" (iOS 14.3)
    //
    // The bug trigger criterions
    // 1. more than 2 AVSpeechSynthesizer instances
    // 2. use delegate with willSpeakRangeOfSpeechString method support
    // 3. speak in certain orders involved multiple english and japanese voices
    //
    // 100% the tts will speak en text in different text(14.2) or skip it(14.3)
    //
    // tested on iPhone SE(2016), iOS 14.2 & 14.3
    //
    // This bug fires randomly in my real app.
    // It took me 2 days to reproduce it in a simple project.
    // Hope this bug will be fix soon or exist any workaround.
    //
    // ps:
    // 1. The reason I need to use multiple AVSpeechSynthesizers is because another bug:
    // If using only one AVSpeechSynthesizer Instance with willSpeakRangeOfSpeechString method delegate
    // In order (en -> ja1 -> ja2) -> (en -> ja1 -> ja2)
    // tts will pause 2 secs before speaking every time

    func speakAll() {
        let enTTS = TTS()
        let jaTTS = TTS()

        let enVoice = AVSpeechSynthesisVoice.speechVoices().filter { $0.language.contains("en") }.first!
        let jaVoice = AVSpeechSynthesisVoice.speechVoices().filter { $0.language.contains("ja") }.first!

        let lines = [
            (text: "pizza", voice: enVoice),
            (text: "鮭", voice: jaVoice),
            (text: "肉", voice: jaVoice),
            (text: "ice cream", voice: enVoice),
            (text: "after skiping bug.", voice: enVoice),
        ]

        var lineIndex = 0
        func sayNextLine() {
            guard lineIndex < lines.count else { return }
            let line = lines[lineIndex]
            let tts = line.voice == enVoice ? enTTS : jaTTS
            lineIndex += 1
            textview.text = "Speaking: \n\(line.text)\n by \(line.voice.identifier)"
            tts.say(text: line.text, voice: line.voice)
        }

        Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
            sayNextLine()
        }
    }
}

class TTS: NSObject, AVSpeechSynthesizerDelegate {
    var synthesizer = AVSpeechSynthesizer()

    func say(text: String, voice: AVSpeechSynthesisVoice) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        synthesizer.delegate = self
        synthesizer.speak(utterance)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        print(utterance.speechString, "said")
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        // do nothing...
        // but with this method will trigger en tts speak wrong text(iOS 14.2) or skipped text (iOS 14.3)
        print("will speak \(utterance.speechString) in range:", characterRange)
    }
}
