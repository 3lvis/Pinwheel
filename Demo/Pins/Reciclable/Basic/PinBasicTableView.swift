import Pinwheel

class PinTableView: View {
    lazy var tableView: TableView = {
        let view = TableView(items: items)
        view.delegate = self
        return view
    }()


    lazy var items: [TableViewItem] = {
        let onlyTitle = TextTableViewItem(title: "Only title")

        let titleAndSubtitle = TextTableViewItem(title: "Title and subtitle", subtitle: "subtitle")

        let titleSubtitleAndDetail = TextTableViewItem(title: "Title, subtitle and detail", subtitle: "subtitle")
        titleSubtitleAndDetail.detailText = "Detail text"

        let titleAndDetail = TextTableViewItem(title: "Title and detail")
        titleAndDetail.detailText = "Detail text"

        let hasChevron = TextTableViewItem(title: "Has chevron")
        hasChevron.hasChevron = true

        let disabled = TextTableViewItem(title: "Is disabled")
        disabled.isEnabled = false

        return [
            onlyTitle,
            titleAndSubtitle,
            titleSubtitleAndDetail,
            titleAndDetail,
            disabled,
            hasChevron
        ]
    }()

    override func setup() {
        addSubview(tableView)
        tableView.fillInSuperview()
    }
}

extension PinTableView: TableViewDelegate {
    func tableView(_ tableView: TableView, didSelectItemAtIndex index: Int) {
    }
}
