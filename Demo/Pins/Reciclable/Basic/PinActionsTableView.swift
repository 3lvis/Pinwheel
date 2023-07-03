import Pinwheel

class PinActionsTableView: View {
    private(set) lazy var view: ActionsTableView = {
        let view = ActionsTableView(title: "Platos Listos", actions: [
            Action(title: "Edit", action: { print("Edit") }),
            Action(title: "Reorder", action: { print("Reorder") }),
            Action(title: "Delete", isCritical: true, action: { print("Delete") }),
        ])
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override func setup() {
        addSubview(view)
        view.fillInSuperview()
    }
}
