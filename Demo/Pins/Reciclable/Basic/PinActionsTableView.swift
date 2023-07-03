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

//    var size: CGSize {
//         let rootController = ActionsController()
//         let expanded = view.frame.height - view.layoutMargins.top
//         let totalHeight = rootController.controllerView.totalHeight(inView: view)
//         let height = BottomSheetHeight(compact: totalHeight, expanded: expanded)
//         let bottomSheet = BottomSheet(rootViewController: rootController, height: height, draggableArea: .everything)
//         present(bottomSheet, animated: true)
//    }

    override func setup() {
        addSubview(view)
        view.fillInSuperview()
    }
}
