import Pinwheel

class PinBasicTableView: View {
    lazy var basicTableView: BasicTableView = {
        let view = BasicTableView(items: items)
        view.delegate = self
        return view
    }()


    lazy var items: [BasicTableViewItem] = {
        var items = [BasicTableViewItem]()
        items.append(BasicTableViewItem(title: "Uno"))
        items.append(BasicTableViewItem(title: "Dos"))
        items.append(BasicTableViewItem(title: "Tres"))

        let disabledItem = BasicTableViewItem(title: "Disabled")
        disabledItem.subtitle = "subtitle"
        disabledItem.isEnabled = false
        disabledItem.hasChevron = true
        items.append(disabledItem)

        return items
    }()

    override func setup() {
        addSubview(basicTableView)
        basicTableView.fillInSuperview()
    }
}

extension PinBasicTableView: BasicTableViewDelegate {
    func basicTableView(_ basicTableView: BasicTableView, didSelectItemAtIndex index: Int) {
    }
}
