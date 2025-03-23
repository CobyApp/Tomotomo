Use this package as a library
Depend on it
Run this command:

With Dart:

 $ dart pub add google_generative_ai
With Flutter:

 $ flutter pub add google_generative_ai
This will add a line like this to your package's pubspec.yaml (and run an implicit dart pub get):

dependencies:
  google_generative_ai: ^0.4.6
Alternatively, your editor might support dart pub get or flutter pub get. Check the docs for your editor to learn more.

Import it
Now in your Dart code, you can use:

import 'package:google_generative_ai/google_generative_ai.dart';

멀티턴 대화
Gemini SDK를 사용하면 여러 번의 질문과 응답을 채팅으로 수집할 수 있습니다. 채팅 형식을 사용하면 사용자가 점진적으로 답변을 찾고 여러 부분으로 구성된 문제에 대한 도움을 받을 수 있습니다. 이 채팅 SDK 구현은 대화 기록을 추적하는 인터페이스를 제공하지만, 백그라운드에서는 동일한 generateContent 메서드를 사용하여 응답을 만듭니다.

다음 코드 예는 기본 채팅 구현을 보여줍니다.

import { GoogleGenerativeAI } from "@google/generative-ai";
const genAI = new GoogleGenerativeAI("GEMINI_API_KEY");
const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });
const chat = model.startChat({
  history: [
    {
      role: "user",
      parts: [{ text: "Hello" }],
    },
    {
      role: "model",
      parts: [{ text: "Great to meet you. What would you like to know?" }],
    },
  ],
});

let result = await chat.sendMessage("I have 2 dogs in my house.");
console.log(result.response.text());
let result2 = await chat.sendMessage("How many paws are in my house?");
console.log(result2.response.text());