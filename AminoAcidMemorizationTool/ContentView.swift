import SwiftUI

struct ContentView: View {
    @State private var showStudyScreen = false
    @State private var selectedStudyItems: Set<String> = []
    
    let studyOptions = [
        "Structures",
        "One Letter Codes",
        "Side Chain pKas",
        "Polarities"
    ]
    
    var isSelectionValid: Bool {
        !selectedStudyItems.isEmpty
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("What would you like to study?")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Select one or more topics to get started")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(studyOptions, id: \.self) { option in
                            SelectionCard(
                                title: option,
                                isSelected: selectedStudyItems.contains(option),
                                action: {
                                    if selectedStudyItems.contains(option) {
                                        selectedStudyItems.remove(option)
                                    } else {
                                        selectedStudyItems.insert(option)
                                    }
                                }
                            )
                        }
                    }
                    .padding(20)
                }
                
                Spacer()
                
                NavigationLink(destination: StudyScreen(selectedItems: Array(selectedStudyItems))) {
                    Text("Let's Study!")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(isSelectionValid ? Color.blue : Color.gray)
                        .cornerRadius(10)
                        .padding(20)
                }
                .disabled(!isSelectionValid)
            }
            .navigationTitle("Amino Acid Flashcards")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct SelectionCard: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .blue : .gray)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(.black)
                
                Spacer()
            }
            .padding(15)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
}

struct StudyScreen: View {
    let selectedItems: [String]
    @State private var currentQuestionIndex = 0
    @State private var score = 0
    @State private var questions: [Question] = []
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isCorrect = false
    @Environment(\.presentationMode) var presentationMode
    
    var currentQuestion: Question? {
        guard currentQuestionIndex < questions.count else { return nil }
        return questions[currentQuestionIndex]
    }
    
    var questionsRemaining: Int {
        questions.count - currentQuestionIndex
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Score Header
                HStack {
                    VStack(alignment: .leading) {
                        Text("Score")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("\(score)/\(currentQuestionIndex)")
                            .font(.headline)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Remaining")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("\(questionsRemaining)")
                            .font(.headline)
                    }
                }
                .padding(20)
                .background(Color(.systemGray6))
                
                if let question = currentQuestion {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Question Content
                            if question.type != .polarities {
                                // Show structure image
                                Image(systemName: "photo")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray)
                                    .frame(height: 150)
                                    .frame(maxWidth: .infinity)
                                    .background(Color(.systemGray5))
                                    .cornerRadius(10)
                            }
                            
                            // Question Text
                            VStack(spacing: 10) {
                                Text(question.questionText)
                                    .font(.headline)
                                    .multilineTextAlignment(.center)
                                
                                if let aminoAcidName = question.aminoAcidName {
                                    Text(aminoAcidName)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Spacer()
                            
                            // Answer Options
                            VStack(spacing: 10) {
                                ForEach(0..<question.options.count, id: \.self) { index in
                                    AnswerButton(
                                        text: question.options[index],
                                        action: {
                                            handleAnswer(index: index, question: question)
                                        }
                                    )
                                }
                            }
                        }
                        .padding(20)
                    }
                } else {
                    VStack(spacing: 20) {
                        Spacer()
                        
                        VStack(spacing: 10) {
                            Text("Quiz Complete!")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text("Final Score: \(score)/\(questions.count)")
                                .font(.headline)
                            
                            let percentage = questions.count > 0 ? (score * 100) / questions.count : 0
                            Text("\(percentage)%")
                                .font(.system(size: 48))
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            Text("Back to Menu")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        .padding(20)
                    }
                }
            }
        }
        .navigationTitle("Study")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            generateQuestions()
        }
        .alert("Result", isPresented: $showAlert) {
            Button("Next") {
                currentQuestionIndex += 1
                showAlert = false
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func generateQuestions() {
        var generatedQuestions: [Question] = []
        
        for selectedItem in selectedItems {
            for amino in AminoAcidDatabase.all {
                switch selectedItem {
                case "Structures":
                    let otherAminos = AminoAcidDatabase.all.filter { $0.name != amino.name }.shuffled().prefix(3)
                    let options = ([amino] + otherAminos).map { $0.name }.shuffled()
                    generatedQuestions.append(Question(
                        type: .structures,
                        questionText: "What amino acid is this?",
                        aminoAcidName: nil,
                        correctAnswer: amino.name,
                        options: options
                    ))
                    
                case "One Letter Codes":
                    let similarCodes = generateSimilarLetterCodes(correct: amino.oneLetterCode, count: 3)
                    let options = (similarCodes + [amino.oneLetterCode]).shuffled()
                    generatedQuestions.append(Question(
                        type: .oneLetterCodes,
                        questionText: "What is the one letter code?",
                        aminoAcidName: amino.name,
                        correctAnswer: amino.oneLetterCode,
                        options: options
                    ))
                    
                case "Side Chain pKas":
                    let similarPKas = generateSimilarPKas(correct: amino.sideChainPKa, count: 3)
                    let options = (similarPKas + [String(format: "%.2f", amino.sideChainPKa)]).shuffled()
                    generatedQuestions.append(Question(
                        type: .sideChainPKas,
                        questionText: "What is the side chain pKa?",
                        aminoAcidName: amino.name,
                        correctAnswer: String(format: "%.2f", amino.sideChainPKa),
                        options: options
                    ))
                    
                case "Polarities":
                    let options = [amino.polarity, amino.polarity == "Polar" ? "Non-polar" : "Polar"].shuffled()
                    generatedQuestions.append(Question(
                        type: .polarities,
                        questionText: "Is this amino acid polar or non-polar?",
                        aminoAcidName: amino.name,
                        correctAnswer: amino.polarity,
                        options: options
                    ))
                    
                default:
                    break
                }
            }
        }
        
        questions = generatedQuestions.shuffled()
    }
    
    private func handleAnswer(index: Int, question: Question) {
        let selectedAnswer = question.options[index]
        let correct = selectedAnswer == question.correctAnswer
        
        if correct {
            score += 1
            alertMessage = "Correct! ✓"
        } else {
            alertMessage = "Incorrect. The correct answer is: \(question.correctAnswer)"
        }
        
        showAlert = true
    }
    
    private func generateSimilarLetterCodes(correct: String, count: Int) -> [String] {
        let allLetters = "ACDEFGHIKLMNPQRSTVWY"
        return (0..<count).map { _ in
            String(allLetters.randomElement() ?? "X")
        }.filter { $0 != correct }
    }
    
    private func generateSimilarPKas(correct: Double, count: Int) -> [String] {
        var result: [String] = []
        while result.count < count {
            let randomOffset = Double.random(in: -3.0...3.0)
            let newPKa = correct + randomOffset
            if abs(newPKa - correct) >= 0.01 && newPKa > 0 && newPKa < 14 {
                let formatted = String(format: "%.2f", newPKa)
                if !result.contains(formatted) {
                    result.append(formatted)
                }
            }
        }
        return result
    }
}

struct AnswerButton: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.body)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color(.systemGray6))
                .cornerRadius(10)
        }
    }
}

struct Question {
    enum QuestionType {
        case structures
        case oneLetterCodes
        case sideChainPKas
        case polarities
    }
    
    let type: QuestionType
    let questionText: String
    let aminoAcidName: String?
    let correctAnswer: String
    let options: [String]
}

struct AminoAcid {
    let name: String
    let oneLetterCode: String
    let sideChainPKa: Double
    let polarity: String
}

struct AminoAcidDatabase {
    static let all = [
        AminoAcid(name: "Alanine", oneLetterCode: "A", sideChainPKa: 0.0, polarity: "Non-polar"),
        AminoAcid(name: "Arginine", oneLetterCode: "R", sideChainPKa: 12.48, polarity: "Polar"),
        AminoAcid(name: "Asparagine", oneLetterCode: "N", sideChainPKa: 0.0, polarity: "Polar"),
        AminoAcid(name: "Aspartic acid", oneLetterCode: "D", sideChainPKa: 3.65, polarity: "Polar"),
        AminoAcid(name: "Cysteine", oneLetterCode: "C", sideChainPKa: 8.37, polarity: "Polar"),
        AminoAcid(name: "Glutamic acid", oneLetterCode: "E", sideChainPKa: 4.25, polarity: "Polar"),
        AminoAcid(name: "Glutamine", oneLetterCode: "Q", sideChainPKa: 0.0, polarity: "Polar"),
        AminoAcid(name: "Glycine", oneLetterCode: "G", sideChainPKa: 0.0, polarity: "Non-polar"),
        AminoAcid(name: "Histidine", oneLetterCode: "H", sideChainPKa: 6.04, polarity: "Polar"),
        AminoAcid(name: "Isoleucine", oneLetterCode: "I", sideChainPKa: 0.0, polarity: "Non-polar"),
        AminoAcid(name: "Leucine", oneLetterCode: "L", sideChainPKa: 0.0, polarity: "Non-polar"),
        AminoAcid(name: "Lysine", oneLetterCode: "K", sideChainPKa: 10.53, polarity: "Polar"),
        AminoAcid(name: "Methionine", oneLetterCode: "M", sideChainPKa: 0.0, polarity: "Non-polar"),
        AminoAcid(name: "Phenylalanine", oneLetterCode: "F", sideChainPKa: 0.0, polarity: "Non-polar"),
        AminoAcid(name: "Proline", oneLetterCode: "P", sideChainPKa: 0.0, polarity: "Non-polar"),
        AminoAcid(name: "Serine", oneLetterCode: "S", sideChainPKa: 13.15, polarity: "Polar"),
        AminoAcid(name: "Threonine", oneLetterCode: "T", sideChainPKa: 13.12, polarity: "Polar"),
        AminoAcid(name: "Tryptophan", oneLetterCode: "W", sideChainPKa: 0.0, polarity: "Non-polar"),
        AminoAcid(name: "Tyrosine", oneLetterCode: "Y", sideChainPKa: 10.46, polarity: "Polar"),
        AminoAcid(name: "Valine", oneLetterCode: "V", sideChainPKa: 0.0, polarity: "Non-polar"),
    ]
}

#Preview {
    ContentView()
}
