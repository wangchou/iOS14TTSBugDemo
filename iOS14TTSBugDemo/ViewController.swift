//
//  ViewController.swift
//  iOS14TTSBugDemo
//
//  Created by Wangchou Lu on R 2/12/07.
//

import UIKit
import Speech
import Promises // Google/Promises for waiting speak finish

class ViewController: UIViewController {
    @IBOutlet weak var textview: UITextView!
    @IBAction func buttonClicked(_ sender: Any) {
        speakAll()
    }

    // Bug: The English tts will speak "ice cream" as rubbish text after some steps
    //
    // The bug trigger criterions
    // 1. more than 2 AVSpeechSynthesizer instances (here 3 instances)
    // 2. use delegate with willSpeakRangeOfSpeechString method support
    // 3. speak in certain orders involved multiple english and japanese voices
    //
    // 100% the tts will speak en text in different / rubbish text
    //
    // tested on iPhone SE(2016), iOS 14.2
    //
    // This bug fires randomly in my real app.
    // It took me 2 days to reproduce it in a simple project.
    // Hope this bug will be fix soon or exist any workaround.
    //
    // ps:
    // 1. when tts speak japnese, the debug console will show error like
    // 2020-12-07 16:00:26.918598+0800 iOS14TTSBugDemo[533:16036] [AXTTSCommon] Broken user rule: (\d|[Ôºê-Ôºô])(\s)?Ë©± > Error Domain=NSCocoaErrorDomain Code=2048 "The value “(\d|[Ôºê-Ôºô])(\s)?Ë©±” is invalid." UserInfo={NSInvalidValue=(\d|[Ôºê-Ôºô])(\s)?Ë©±}
    //
    // 2. The reason I need to use multiple AVSpeechSynthesis is another bug:
    // If app use 3 voices (ja x 2 & en x 1) on one AVSpeechSynthesizer Instance with willSpeakRangeOfSpeechString method delegate
    // In order (en -> ja1 -> ja2) -> (en -> ja1 -> ja2)
    // tts will pause 2 secs before speaking every time

    func speakAll() {
        let ttss = [TTS(), TTS(), TTS()]

        var lineIndex = 0
        func sayNextLine() -> Promise<Void> {
            guard lineIndex < lines.count else {
                let promise = Promise<Void>.pending()
                promise.fulfill(())
                return promise
            }
            let line = lines[lineIndex]
            let tts = ttss[lineIndex % ttss.count]
            lineIndex += 1
            textview.text = "Speaking: \n\(line.text)\n by \(line.voice.identifier)"
            return tts.say(line)
        }

        var enVoices: [AVSpeechSynthesisVoice] = []
        var jaVoices: [AVSpeechSynthesisVoice] = []
        for voice in AVSpeechSynthesisVoice.speechVoices() {
            if voice.language.contains("en-US") {
                enVoices.append(voice)
            }
            if voice.language.contains("ja-JP") {
                jaVoices.append(voice)
            }
        }

        guard enVoices.count > 4, jaVoices.count > 2 else {
            print("\nThis demo need to run on real device with more than 2 ja voices and 4 en voices.\n")
            return
        }

        let lines: [(text: String, voice: AVSpeechSynthesisVoice)] = [
            (text: "pizza", voice: enVoices[0]),
            (text: "pizza", voice: enVoices[1]),
            (text: "pizza", voice: enVoices[2]),
            (text: "pizza", voice: enVoices[3]),
            (text: "pizza", voice: enVoices[0]),
            (text: "pizza", voice: enVoices[0]),
            (text: "鮭", voice: jaVoices[0]),
            (text: "肉", voice: jaVoices[1]),
            (text: "ice cream", voice: enVoices[0]),
            (text: "鮭", voice: jaVoices[0]),
            (text: "肉", voice: jaVoices[1]),
            (text: "ice cream", voice: enVoices[0]),
            (text: "鮭", voice: jaVoices[0]),
            (text: "肉", voice: jaVoices[1]),
            (text: "ice cream", voice: enVoices[0]),
            (text: "鮭", voice: jaVoices[0]),
            (text: "肉", voice: jaVoices[1]),
            (text: "ice cream", voice: enVoices[0]),
        ]

        let startTime = NSDate().timeIntervalSince1970
        sayNextLine()
            .then(sayNextLine)
            .then(sayNextLine)
            .then(sayNextLine)
            .then(sayNextLine)
            .then(sayNextLine)
            .then(sayNextLine)
            .then(sayNextLine)
            .then(sayNextLine)
            .then(sayNextLine)
            .then(sayNextLine)
            .then(sayNextLine)
            .then(sayNextLine)
            .then(sayNextLine)
            .then(sayNextLine)
            .then(sayNextLine)
            .then(sayNextLine)
            .then(sayNextLine)
            .always {
                print(String(format: "finished time: %.3f", NSDate().timeIntervalSince1970 - startTime))
            }
    }
}

class TTS: NSObject, AVSpeechSynthesizerDelegate {
    var synthesizer = AVSpeechSynthesizer()
    var promise = Promise<Void>.pending()

    func say(_ line: (text: String, voice: AVSpeechSynthesisVoice)) -> Promise<Void> {
        promise = Promise<Void>.pending()
        let utterance = AVSpeechUtterance(string: line.text)
        utterance.voice = line.voice
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
        // but with this method will trigger en tts speak wrong text
        // and delay speaking for 2 secs (en_voice1 -> ja_voice1 -> ja_voice2) ^ n times
    }
}
