rm -r SQuAD
rm -r NewsQA
rm -r TriviaQA
rm -r HotpotQA
rm -r NaturalQuestions 
cp -r single_domain SQuAD
cp -r checkpoints/SQuAD/step_best/ SQuAD/squad/checkpoints/
cp -r single_domain NewsQA
cp -r checkpoints/NewsQA/step_best/ NewsQA/squad/checkpoints/
cp -r single_domain TriviaQA
cp -r checkpoints/TriviaQA/step_best/ TriviaQA/squad/checkpoints/
cp -r single_domain HotpotQA
cp -r checkpoints/HotpotQA/step_best/ HotpotQA/squad/checkpoints/
cp -r single_domain NaturalQuestions
cp -r checkpoints/NaturalQuestions/step_best/ NaturalQuestions/squad/checkpoints/
