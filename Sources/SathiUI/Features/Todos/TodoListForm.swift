import SathiCore
import SwiftUI

struct TodoListForm: View {
    let list: TodoList?
    let onClose: () -> Void
    @State private var name: String
    @State private var colorHex: String
    @State private var accountID: String?
    @State private var loaded: [TodoAccount]?
    @EnvironmentObject var e: Engine

    init(name: String = "", colorHex: String = Limits.todoListColors[0], accountID: String? = nil, onClose: @escaping () -> Void) {
        list = nil
        self.onClose = onClose
        _name = State(initialValue: name)
        _colorHex = State(initialValue: colorHex)
        _accountID = State(initialValue: accountID)
    }

    init(list: TodoList, name: String, onClose: @escaping () -> Void) {
        self.list = list
        self.onClose = onClose
        _name = State(initialValue: name)
        _colorHex = State(initialValue: list.colorHex)
        _accountID = State(initialValue: list.accountID)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.todoFormSpacing) {
            Text(verbatim: list == nil ? Copywriter.todoNewList : Copywriter.todoRenameList)
                .font(Typography.cardTitle)
                .foregroundStyle(Night.text)
            VStack(alignment: .leading, spacing: UIMetrics.todoChipSpacing) {
                SectionLabel(Copywriter.todoListName)
                TextField(Copywriter.todoListName, text: $name)
                    .textFieldStyle(.plain)
                    .font(Typography.tracker(UIMetrics.todoRowTitleFont, .medium))
                    .foregroundStyle(Night.text)
                    .padding(UIMetrics.todoAddPadding)
                    .background(RoundedRectangle(cornerRadius: UIMetrics.todoAddRadius, style: .continuous).fill(Night.bg))
                    .onSubmit(save)
                    .accessibilityIdentifier("todos.listform.name")
            }
            if list == nil {
                TodoListSwatches(selection: $colorHex)
                accounts
            }
            Text(verbatim: Copywriter.todoListFormHint)
                .font(Typography.hint)
                .foregroundStyle(Night.faint)
            HStack(spacing: UIMetrics.todoChipSpacing) {
                Spacer(minLength: 0)
                Button(action: onClose) {
                    Text(verbatim: Copywriter.todoCancel).accessibilityIdentifier("todos.listform.cancel")
                }
                .buttonStyle(GhostButton(accent: Night.muted))
                Button(action: save) {
                    Text(verbatim: list == nil ? Copywriter.todoCreate : Copywriter.todoRename)
                        .accessibilityIdentifier("todos.listform.save")
                }
                .buttonStyle(GhostButton(accent: Night.todo))
                .disabled(!canSave)
            }
        }
        .onAppear(perform: loadAccounts)
        .onChange(of: e.todoSnapshot) { _ in loadAccounts() }
        .padding(UIMetrics.todoFormPadding)
        .frame(width: UIMetrics.todoFormWidth, alignment: .leading)
        .background(Night.card)
    }

    private var trimmed: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var allAccounts: [TodoAccount] { loaded ?? e.todos.accounts() }
    private var account: String? {
        accountID ?? TodoRules.defaultAccountID(accounts: allAccounts, preferred: e.data.prefs.todos.newListAccountID)
    }
    private var canSave: Bool { !trimmed.isEmpty && (list != nil || account != nil) }

    private var accounts: some View {
        VStack(alignment: .leading, spacing: UIMetrics.todoChipSpacing) {
            SectionLabel(Copywriter.todoListAccount)
            HStack(spacing: UIMetrics.todoChipSpacing) {
                ForEach(allAccounts.filter(\.allowsNewLists), id: \.id) { a in
                    Button { accountID = a.id } label: {
                        Text(verbatim: a.name).accessibilityIdentifier("todos.listform.account.\(a.id)")
                    }
                    .buttonStyle(GhostButton(
                        accent: a.id == account ? Night.todo : Night.chipText,
                        border: a.id == account ? Night.todo : Night.fieldBorder
                    ))
                    .accessibilityAddTraits(a.id == account ? .isSelected : [])
                }
            }
        }
    }

    private func loadAccounts() {
        loaded = e.todos.accounts()
    }

    private func save() {
        guard canSave else { return }
        let engine = e
        let close = onClose
        let n = trimmed
        if let list {
            Task { if case .done = await engine.renameTodoList(list.id, to: n) { close() } }
        } else {
            let draft = TodoListDraft(name: n, colorHex: colorHex, accountID: account ?? "")
            Task { if case .done = await engine.createTodoList(draft) { close() } }
        }
    }
}
