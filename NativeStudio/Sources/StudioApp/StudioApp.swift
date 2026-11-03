import SwiftUI
import SwiftData

@main
struct StudioApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Subject.self, StudySession.self, Exam.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do { return try ModelContainer(for: schema, configurations: [configuration]) }
        catch { fatalError("Impossibile inizializzare il database: \(error)") }
    }()

    var body: some Scene {
        WindowGroup {
            StudioRootView()
        }
        .modelContainer(sharedModelContainer)
    }
}

@Model
final class Subject {
    var name: String
    var symbol: String
    var tint: String
    var examDate: Date?
    var goalHours: Double
    var completedTopics: Int
    var totalTopics: Int
    @Relationship(deleteRule: .cascade, inverse: \StudySession.subject) var sessions: [StudySession] = []
    @Relationship(deleteRule: .cascade, inverse: \Exam.subject) var exams: [Exam] = []

    init(name: String, symbol: String, tint: String, examDate: Date? = nil, goalHours: Double = 24, completedTopics: Int = 0, totalTopics: Int = 12) {
        self.name = name; self.symbol = symbol; self.tint = tint; self.examDate = examDate
        self.goalHours = goalHours; self.completedTopics = completedTopics; self.totalTopics = totalTopics
    }
}

@Model
final class StudySession {
    var date: Date
    var minutes: Int
    var topic: String
    var subject: Subject?
    init(date: Date = .now, minutes: Int, topic: String, subject: Subject? = nil) {
        self.date = date; self.minutes = minutes; self.topic = topic; self.subject = subject
    }
}

@Model
final class Exam {
    var name: String
    var grade: Int
    var cfu: Int
    var date: Date
    var subject: Subject?
    init(name: String, grade: Int, cfu: Int, date: Date = .now, subject: Subject? = nil) {
        self.name = name; self.grade = grade; self.cfu = cfu; self.date = date; self.subject = subject
    }
}

enum AppTheme: String, CaseIterable, Identifiable {
    case light, dark, glass
    var id: String { rawValue }
    var label: String { switch self { case .light: "Chiaro"; case .dark: "Scuro"; case .glass: "Liquid Glass" } }
    var colorScheme: ColorScheme? { self == .dark ? .dark : nil }
}

struct StudioRootView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Subject.name) private var subjects: [Subject]
    @Query(sort: \Exam.date, order: .reverse) private var exams: [Exam]
    @AppStorage("theme") private var themeName = AppTheme.light.rawValue
    @State private var showSessionSheet = false
    @State private var didSeed = false

    private var theme: AppTheme { AppTheme(rawValue: themeName) ?? .light }
    private var weightedAverage: Double {
        let credits = exams.reduce(0) { $0 + $1.cfu }
        guard credits > 0 else { return 0 }
        return Double(exams.reduce(0) { $0 + $1.grade * $1.cfu }) / Double(credits)
    }
    private var arithmeticAverage: Double { exams.isEmpty ? 0 : Double(exams.reduce(0) { $0 + $1.grade }) / Double(exams.count) }

    var body: some View {
        Group {
            if subjects.isEmpty { ProgressView().task { seedData() } }
            else { NavigationSplitView { Sidebar() } detail: { DashboardView(subjects: subjects, exams: exams, weightedAverage: weightedAverage, arithmeticAverage: arithmeticAverage, showSessionSheet: $showSessionSheet) } }
        }
        .preferredColorScheme(theme.colorScheme)
        .tint(.indigo)
        .sheet(isPresented: $showSessionSheet) { AddSessionSheet(subjects: subjects) }
        .toolbar { ToolbarItem(placement: .automatic) { Picker("Aspetto", selection: $themeName) { ForEach(AppTheme.allCases) { Text($0.label).tag($0.rawValue) } }.pickerStyle(.menu) } }
        .background(theme == .glass ? AnyView(GlassBackground()) : AnyView(Color.primary.opacity(0.035)))
    }

    private func seedData() {
        guard !didSeed else { return }; didSeed = true
        let calendar = Calendar.current
        let analysis = Subject(name: "Analisi matematica II", symbol: "λ", tint: "violet", examDate: calendar.date(byAdding: .day, value: 82, to: .now), goalHours: 28, completedTopics: 8, totalTopics: 12)
        let physics = Subject(name: "Fisica II", symbol: "⌁", tint: "blue", examDate: calendar.date(byAdding: .day, value: 89, to: .now), goalHours: 26, completedTopics: 5, totalTopics: 12)
        let coding = Subject(name: "Programmazione", symbol: "⌘", tint: "green", examDate: calendar.date(byAdding: .day, value: 96, to: .now), goalHours: 20, completedTopics: 4, totalTopics: 12)
        [analysis, physics, coding].forEach(context.insert)
        for offset in 0..<12 { context.insert(StudySession(date: calendar.date(byAdding: .day, value: -offset, to: .now)!, minutes: 60, topic: "Ripasso", subject: analysis)) }
        for offset in 0..<5 { context.insert(StudySession(date: calendar.date(byAdding: .day, value: -offset, to: .now)!, minutes: 55, topic: "Esercizi", subject: physics)) }
        context.insert(Exam(name: "Geometria", grade: 28, cfu: 9))
        context.insert(Exam(name: "Algebra lineare", grade: 27, cfu: 6))
        try? context.save()
    }
}

struct Sidebar: View {
    var body: some View {
        List { Label("Oggi", systemImage: "house.fill").tag(0); Label("Materie", systemImage: "square.grid.2x2"); Label("Calendario", systemImage: "calendar"); Label("Esami", systemImage: "graduationcap"); Label("Statistiche", systemImage: "chart.line.uptrend.xyaxis") }
            .navigationTitle("Studio")
    }
}

struct DashboardView: View {
    let subjects: [Subject]; let exams: [Exam]; let weightedAverage: Double; let arithmeticAverage: Double
    @Binding var showSessionSheet: Bool
    private var weeklyMinutes: Int { subjects.flatMap(\.sessions).filter { Calendar.current.isDate($0.date, equalTo: .now, toGranularity: .weekOfYear) }.reduce(0) { $0 + $1.minutes } }
    private var suggestion: Subject { subjects.min { $0.sessions.last?.date ?? .distantPast < $1.sessions.last?.date ?? .distantPast } ?? subjects[0] }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 7) { Text("IL TUO SEMESTRE").sectionCaption(); Text("Buongiorno, Stefano.").font(.system(size: 38, weight: .bold, design: .rounded)); Text("Un piccolo passo oggi costruisce il risultato di domani.").foregroundStyle(.secondary) }
                    Spacer(); Button { showSessionSheet = true } label: { Label("Inizia a studiare", systemImage: "plus") }.buttonStyle(.borderedProminent).controlSize(.large)
                }
                LazyVGrid(columns: [GridItem(.flexible(minimum: 250), spacing: 14), GridItem(.flexible(minimum: 180), spacing: 14), GridItem(.flexible(minimum: 180), spacing: 14)], spacing: 14) {
                    MetricCard(title: "Obiettivo settimanale", value: "\(weeklyMinutes / 60)h \(weeklyMinutes % 60)m", subtitle: "di 12 ore", progress: min(Double(weeklyMinutes) / 720, 1))
                    MetricCard(title: "Sessioni questa settimana", value: "\(subjects.flatMap(\.sessions).filter { Calendar.current.isDate($0.date, equalTo: .now, toGranularity: .weekOfYear) }.count)", subtitle: "Continua così", progress: nil)
                    MetricCard(title: "Costanza complessiva", value: "\(consistency)%", subtitle: "Ottimo ritmo", progress: nil)
                }
                HStack(alignment: .top, spacing: 16) {
                    Card { VStack(alignment: .leading, spacing: 12) { HStack { VStack(alignment: .leading) { Text("PIANO DI OGGI").sectionCaption(); Text("Cosa c'è in programma").font(.title3.bold()) }; Spacer(); Button("Modifica") {}.buttonStyle(.plain).foregroundStyle(.secondary) }; ForEach(subjects) { subject in StudyRow(subject: subject) }; Button("+ Aggiungi al piano") {}.buttonStyle(.plain).foregroundStyle(.secondary) } }.frame(maxWidth: .infinity)
                    Card { VStack(alignment: .leading, spacing: 14) { Image(systemName: "sparkles").foregroundStyle(.yellow); Text("IL TUO ASSISTENTE").sectionCaption(); Text("Un consiglio per oggi").font(.title3.bold()); Text("\(suggestion.name) è la materia meno recente. Una sessione breve oggi mantiene la tua costanza prima dell'esame.").foregroundStyle(.secondary); Button("Pianifica 45 minuti") { showSessionSheet = true }.buttonStyle(.borderedProminent) } }.frame(width: 300)
                }
                VStack(alignment: .leading, spacing: 14) { HStack { VStack(alignment: .leading) { Text("LE TUE MATERIE").sectionCaption(); Text("La tua costanza").font(.title3.bold()) }; Spacer(); Button("Vedi tutte") {}.buttonStyle(.plain) }; LazyVGrid(columns: [GridItem(.adaptive(minimum: 230), spacing: 14)], spacing: 14) { ForEach(subjects) { SubjectCard(subject: $0) } } }
                Card { HStack { VStack(alignment: .leading) { Text("CARRIERA").sectionCaption(); Text("Media e crediti").font(.title3.bold()) }; Spacer(); VStack(alignment: .trailing) { Text("Media aritmetica  \(arithmeticAverage, specifier: "%.1f")"); Text("Media ponderata  \(weightedAverage, specifier: "%.1f")").font(.headline); Text("CFU acquisiti  \(exams.reduce(0) { $0 + $1.cfu }) / 180").foregroundStyle(.secondary) } } }
            }.padding(32).frame(maxWidth: 1180)
        }.navigationTitle("Oggi").background(Color.primary.opacity(0.035))
    }
    private var consistency: Int { min(100, Int(Double(weeklyMinutes) / 720 * 100)) }
}

struct StudyRow: View {
    let subject: Subject
    var body: some View {
        HStack { Text(subject.symbol).font(.title3).frame(width: 38, height: 38).background(.indigo.opacity(0.12), in: RoundedRectangle(cornerRadius: 10)); VStack(alignment: .leading) { Text(subject.name).fontWeight(.semibold); Text("Ripasso programmato").font(.caption).foregroundStyle(.secondary) }; Spacer(); Text("45 min").font(.caption).foregroundStyle(.secondary); Image(systemName: "play.fill").font(.caption).padding(9).background(.quaternary, in: Circle()) }.padding(.vertical, 7)
    }
}
struct SubjectCard: View {
    let subject: Subject
    private var hours: Double { Double(subject.sessions.reduce(0) { $0 + $1.minutes }) / 60 }
    private var streak: Int { let days = Set(subject.sessions.map { Calendar.current.startOfDay(for: $0.date) }); var value = 0; var current = Calendar.current.startOfDay(for: .now); while days.contains(current) { value += 1; current = Calendar.current.date(byAdding: .day, value: -1, to: current)! }; return value }
    var body: some View {
        Card { VStack(alignment: .leading, spacing: 12) { HStack { Text(subject.symbol).font(.title3).padding(9).background(.indigo.opacity(0.12), in: RoundedRectangle(cornerRadius: 10)); Spacer(); Label("\(streak) giorni", systemImage: streak > 6 ? "flame.fill" : "circle.fill").font(.caption).foregroundStyle(streak > 6 ? .orange : .green) }; Text(subject.name).font(.headline); Text(subject.examDate?.formatted(date: .abbreviated, time: .omitted) ?? "Data da fissare").font(.caption).foregroundStyle(.secondary); ProgressView(value: Double(subject.completedTopics), total: Double(subject.totalTopics)); HStack { Text("\(Int(Double(subject.completedTopics) / Double(subject.totalTopics) * 100))% del programma"); Spacer(); Text("\(hours, specifier: "%.1f")h") }.font(.caption).foregroundStyle(.secondary) } }
    }
}
struct MetricCard: View {
    let title: String; let value: String; let subtitle: String; let progress: Double?
    var body: some View { Card { VStack(alignment: .leading, spacing: 10) { Text(title).font(.subheadline).foregroundStyle(.secondary); HStack(alignment: .lastTextBaseline, spacing: 6) { Text(value).font(.title2.bold()); Text(subtitle).font(.caption).foregroundStyle(.secondary) }; if let progress { ProgressView(value: progress).tint(.indigo) } else { Text(subtitle).font(.caption).foregroundStyle(.green) } } } }
}
struct Card<Content: View>: View { @ViewBuilder var content: Content; var body: some View { content.padding(20).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 17)).overlay(RoundedRectangle(cornerRadius: 17).stroke(.white.opacity(0.22))) } }
struct GlassBackground: View { var body: some View { LinearGradient(colors: [.blue.opacity(0.22), .pink.opacity(0.18), .indigo.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea() } }
extension View { func sectionCaption() -> some View { font(.caption2.weight(.bold)).tracking(1).foregroundStyle(.secondary) } }

struct AddSessionSheet: View {
    @Environment(\.dismiss) private var dismiss; @Environment(\.modelContext) private var context
    let subjects: [Subject]; @State private var subject: Subject?; @State private var minutes = 45; @State private var topic = ""
    var body: some View { NavigationStack { Form { Picker("Materia", selection: $subject) { Text("Scegli una materia").tag(Subject?.none); ForEach(subjects) { Text($0.name).tag(Optional($0)) } }; Stepper("Durata: \(minutes) minuti", value: $minutes, in: 15...300, step: 15); TextField("Argomento studiato", text: $topic) }.navigationTitle("Nuova sessione").toolbar { ToolbarItem(placement: .cancellationAction) { Button("Annulla") { dismiss() } }; ToolbarItem(placement: .confirmationAction) { Button("Salva") { guard let subject else { return }; context.insert(StudySession(minutes: minutes, topic: topic.isEmpty ? "Sessione di studio" : topic, subject: subject)); try? context.save(); dismiss() }.disabled(subject == nil) } } }.frame(minWidth: 360, minHeight: 250) }
}
