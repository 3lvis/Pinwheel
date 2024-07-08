import Pinwheel

class PinTableView: View, Tweakable {
    lazy var tweaks: [Tweak] = {
        return [
            TextTweak(title: "Loading") {
                self.tableView.state = .loading("Loading...", "Please wait while we fetch your details.")
            },
            TextTweak(title: "Loaded") {
                self.tableView.state = .loaded([TextTableViewItem(title: "Only value")])
            },
            TextTweak(title: "Empty") {
                self.tableView.state = .empty("Ready to Move?", "Kick things off with your first booking.")
            },
            TextTweak(title: "Failed") {
                self.tableView.state = .failed("Oops!", "We couldn't load your bookings.", "Retry")
            }
        ]
    }()

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

        let off = BoolTableViewItem(title: "Off")
        let on = BoolTableViewItem(title: "On")
        on.isOn = true

        return [
            onlyTitle,
            titleAndSubtitle,
            titleSubtitleAndDetail,
            titleAndDetail,
            disabled,
            hasChevron,
            off,
            on
        ]
    }()

    override func setup() {
        addSubview(tableView)
        tableView.fillInSuperview()
    }
}

extension PinTableView: TableViewDelegate {
    func tableView(_ tableView: Pinwheel.TableView, didSwitchItem boolTableViewItem: Pinwheel.BoolTableViewItem, atIndex index: Int) {
        let title = "Changed \(boolTableViewItem.title) to \(boolTableViewItem.isOn ? "on" : "off")"
        print(title)
    }
    
    func tableView(_ tableView: TableView, didSelectItemAtIndex index: Int) {
        let title = "Selected \((items[index] as? TextTableViewItem)?.title ?? "")"
        print(title)
    }
}
