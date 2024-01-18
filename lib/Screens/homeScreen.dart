import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:text_to_speech/text_to_speech.dart';

import '../API/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  TextEditingController userInputTextEditingController =
      TextEditingController();
  final SpeechToText speechToTextInstance = SpeechToText();
  final TextToSpeech textToSpeechInstance = TextToSpeech();
  bool speakMOMO = true;
  String recordedAudioString = "";
  bool isLoading = false;
  String modeOpenAI = "chat";
  String imageUrlFromOpenAI = "";
  String answerTextFromOpenAI = "";
  String displayUserQuestion = " ";

  double rate = 2;

  double volume = 50;

  double pitch = 1;

  void initializeSpeechToText() async {
    await speechToTextInstance.initialize();

    setState(() {});
  }

  void startListeningNow() async {
    FocusScope.of(context).unfocus();

    await speechToTextInstance.listen(onResult: onSpeechToTextResult);

    setState(() {});
  }

  void stopListeningNow() async {
    await speechToTextInstance.stop();

    setState(() {});
  }

  void onSpeechToTextResult(SpeechRecognitionResult recognitionResult) {
    recordedAudioString = recognitionResult.recognizedWords;

    speechToTextInstance.isListening
        ? null
        : sendRequestToOpenAI(recordedAudioString);

    print("Speech Result:");
    print(recordedAudioString);
  }

  Future<void> sendRequestToOpenAI(String userInput) async {
    stopListeningNow();

    setState(() {
      isLoading = true;
    });

    //send the request to openAI using our APIService
    await APIService().requestOpenAI(userInput, modeOpenAI, 2000).then((value) {
      setState(() {
        isLoading = false;
      });

      if (value.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Api Key you are/were using expired or it is not working anymore.",
            ),
          ),
        );
      }

      userInputTextEditingController.clear();

      final responseAvailable = jsonDecode(value.body);

      if (modeOpenAI == "chat") {
        setState(() {
          answerTextFromOpenAI = utf8.decode(
              responseAvailable["choices"][0]["text"].toString().codeUnits);

          print(displayUserQuestion);
          print("ChatGPT Chat-bot: ");

          print(answerTextFromOpenAI);

          if (speakMOMO == true) {
            textToSpeechInstance.setVolume(volume);
            textToSpeechInstance.setRate(rate);
            textToSpeechInstance.setPitch(pitch);
            textToSpeechInstance.speak(answerTextFromOpenAI);
          }
        });
      } else {
        //image generation
        setState(() {
          imageUrlFromOpenAI = responseAvailable["data"][0]["url"];

          print("Generated Dale E Image Url: ");
          print(imageUrlFromOpenAI);
        });
      }
    }).catchError((errorMessage) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error: $errorMessage",
          ),
        ),
      );
    });
  }

  @override
  void initState() {
    super.initState();
    displayUserQuestion = userInputTextEditingController.text;
    initializeSpeechToText();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        // floatingActionButton: FloatingActionButton(
        //   backgroundColor: Colors.white,
        //   onPressed: () {
        //     if (!isLoading) {
        //       setState(() {
        //         speakMOMO = !speakMOMO;
        //       });
        //       textToSpeechInstance.stop();
        //     }
        //   },
        //   child: speakMOMO
        //       ? Padding(
        //           padding: const EdgeInsets.all(4.0),
        //           child: Image.asset("Images/sound.png"),
        //         )
        //       : Padding(
        //           padding: const EdgeInsets.all(4.0),
        //           child: Image.asset("Images/mute.png"),
        //         ),
        // ),
        appBar: AppBar(
          flexibleSpace: Container(
              // decoration: BoxDecoration(
              //     gradient: LinearGradient(
              //         colors: [
              //           Colors.white,
              //           //Colors.purpleAccent.shade100,
              //           Colors.indigo.shade900
              //
              //         ]
              //     )
              // ),
              ),
          backgroundColor: Colors.black,
          title: Text(
            "[ Evyan OpenAI ChatBoT ]",
            style: TextStyle(color: Colors.white70),
          ),
          titleSpacing: 10,
          elevation: 2,
          actions: [
            GestureDetector(
              onTap: () {
                if (!isLoading) {
                  setState(() {
                    speakMOMO = !speakMOMO;
                  });
                  textToSpeechInstance.stop();
                }
              },
              child: speakMOMO
                  ? Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Image.asset("Images/sound.png"),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Image.asset("Images/mute.png"),
                    ),
            ),
            //chat
            Padding(
              padding: const EdgeInsets.only(right: 4, top: 4),
              child: InkWell(
                onTap: () {
                  setState(() {
                    modeOpenAI = "chat";
                  });
                },
                child: Icon(
                  Icons.chat,
                  size: 40,
                  color: modeOpenAI == "chat"
                      ? Colors.greenAccent.shade100
                      : Colors.grey,
                ),
              ),
            ),

            //image
            Padding(
              padding: const EdgeInsets.only(right: 8, left: 4),
              child: InkWell(
                onTap: () {
                  setState(() {
                    modeOpenAI = "image";
                  });
                },
                child: Icon(
                  Icons.image,
                  size: 40,
                  color: modeOpenAI == "image" ? Colors.white : Colors.grey,
                ),
              ),
            ),
          ],
        ),
        body: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          color: Colors.black,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.purpleAccent),
                        borderRadius: BorderRadius.all(Radius.circular(15))),
                    height: MediaQuery.of(context).size.height * 0.1,
                    width: MediaQuery.of(context).size.width,
                    child: Expanded(
                      child: Text("${recordedAudioString} : ",
                          style: TextStyle(
                              fontStyle: FontStyle.normal,
                              fontFamily: 'firaCodeFontFamily',
                              color: Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Center(
                    child: InkWell(
                      onTap: () {
                        speechToTextInstance.isListening
                            ? stopListeningNow()
                            : startListeningNow();
                      },
                      child: speechToTextInstance.isListening
                          ? Center(
                              child: LoadingAnimationWidget.fallingDot(
                                size: 400,
                                color: speechToTextInstance.isListening
                                    ? Colors.purple.shade700
                                    : isLoading
                                        ? Colors.deepPurple[400]!
                                        : Colors.deepPurple[200]!,
                              ),
                            )
                          : Image.asset(
                              "Images/final.jpg",
                              height: 400,
                              width: MediaQuery.of(context).size.width,
                            ),
                    ),
                  ),

                  const SizedBox(
                    height: 50,
                  ),

                  //text field with a button
                  Row(
                    children: [
                      //text field
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4.0),
                          child: TextField(
                            style: TextStyle(
                                fontStyle: FontStyle.italic,
                                fontFamily: 'codeFontFamily',
                                color: Colors.white70,
                                fontSize: 15),
                            controller: userInputTextEditingController,
                            decoration: InputDecoration(
                              enabledBorder: const OutlineInputBorder(
                                borderSide:
                                    BorderSide(width: 0.3, color: Colors.cyan),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: const BorderSide(
                                    width: 0.3, color: Colors.purple),
                              ),
                              border: OutlineInputBorder(
                                borderSide: const BorderSide(
                                    width: 3, color: Colors.white),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              hintText: "\t how can i help you?",
                              hintTextDirection: TextDirection.ltr,
                              hintStyle: const TextStyle(color: Colors.white54),
                              filled: true,
                              fillColor: Colors.white12,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        width: 10,
                      ),

                      //button
                      InkWell(
                        onTap: () {
                          if (userInputTextEditingController.text.isNotEmpty) {
                            sendRequestToOpenAI(
                                userInputTextEditingController.text.toString());
                          }
                        },
                        child: AnimatedContainer(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                              shape: BoxShape.rectangle,
                              color: Colors.indigo.shade900),
                          duration: const Duration(
                            milliseconds: 1000,
                          ),
                          curve: Curves.bounceInOut,
                          child: const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                    ],
                  ),

                  //text to show to user

                  const SizedBox(
                    height: 24,
                  ),

                  modeOpenAI == "chat"
                      ? Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              border: Border.all(color: Colors.purpleAccent),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(15))),
                          height: MediaQuery.of(context).size.height,
                          width: MediaQuery.of(context).size.width,
                          child: SelectableText(answerTextFromOpenAI,
                              style: TextStyle(
                                  fontStyle: FontStyle.normal,
                                  fontFamily: 'firaCodeFontFamily',
                                  color: Colors.white70,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                        )
                      : modeOpenAI == "image" && imageUrlFromOpenAI.isNotEmpty
                          ? Column(
                              children: [
                                Image.network(
                                  imageUrlFromOpenAI,
                                  scale: 3.3,
                                ),
                                const SizedBox(
                                  height: 14,
                                ),
                                // ElevatedButton(
                                //   onPressed: ()  async {
                                //     String? imageStatus = await ImageDownloader.downloadImage(imageUrlFromOpenAI);
                                //
                                //     if(imageStatus != null){
                                //       ScaffoldMessenger.of(context).showSnackBar(
                                //         const SnackBar(content: Text("Image Downloaded Successfully"))
                                //       );
                                //     }
                                //   },
                                //   style: ElevatedButton.styleFrom(
                                //       backgroundColor: Colors.black),
                                //   child: const Text(" Download this Image ",
                                //   style: TextStyle(
                                //     color: Colors.white,
                                //
                                //   ),),
                                // ),
                              ],
                            )
                          : Container()
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
