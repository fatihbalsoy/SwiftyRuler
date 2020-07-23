//
//  ViewController.swift
//  SwiftyRuler
//
//  Created by Fatih Balsoy on 06/21/2020.
//  Copyright (c) 2020 Fatih Balsoy. All rights reserved.
//

import SnapKit
import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    let examples: [(UIViewController, String)] = [
        (HorizontalRuler(), "Horizontal"),
        (VerticalRuler(), "Vertical"),
        (DocumentRuler(), "Document")
    ]
    let table = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "SwiftyRuler Examples"
        navigationController?.setNavigationBarHidden(false, animated: true)
        table.delegate = self
        table.dataSource = self

        view.addSubview(table)
        table.snp.makeConstraints { make in
            make.left.top.right.bottom.equalTo(view)
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return examples.count
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let controller = examples[indexPath.row].0
        controller.title = examples[indexPath.row].1
        controller.view.backgroundColor = .systemBackground
        navigationController?.pushViewController(controller, animated: true)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        cell.textLabel?.text = examples[indexPath.row].1
        return cell
    }
}
