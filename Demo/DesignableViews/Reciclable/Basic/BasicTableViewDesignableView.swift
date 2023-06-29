import Designable

class BasicTableViewDesignableView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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

    func setup() {
        addSubview(basicTableView)
        basicTableView.fillInSuperview()
    }
}

extension BasicTableViewDesignableView: BasicTableViewDelegate {
    func basicTableView(_ basicTableView: BasicTableView, didSelectItemAtIndex index: Int) {
    }
}
