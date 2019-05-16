import UIKit

class TaskListViewController: UIViewController {
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var balloon: Balloon!
  
  // Variables
  var taskList: [Task] = []
  var timer: Timer?
  // Animation variables
  var displayLink: CADisplayLink?
  var startTime: CFTimeInterval?, endTime: CFTimeInterval?
  let animationDuration = 3.0
  var height: CGFloat = 0
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
      target: self,
      action: #selector(presentAlertController))
  }
}

// MARK: - UITableViewDelegate
extension TaskListViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard let cell = tableView.cellForRow(at: indexPath) as? TaskTableViewCell else {
      return
    }
    
    cell.updateState()
    
    //TJ01
    showCongratulationsIfNeeded()
  }
}

// MARK: - UITableViewDataSource
extension TaskListViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView,
                 numberOfRowsInSection section: Int) -> Int {
    return taskList.count
  }
  
  func tableView(_ tableView: UITableView,
    cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath)
    
    if let cell = cell as? TaskTableViewCell {
      cell.task = taskList[indexPath.row]
    }
    
    return cell
  }
}

// MARK: - Actions
extension TaskListViewController {
  @objc func presentAlertController(_ sender: UIBarButtonItem) {
    
    createTimer()
    
    let alertController = UIAlertController(title: "Task name",
      message: nil,
      preferredStyle: .alert)
    alertController.addTextField { textField in
      textField.placeholder = "Task name"
      textField.autocapitalizationType = .sentences
    }
    let createAction = UIAlertAction(title: "OK", style: .default) {
      [weak self, weak alertController] _ in
      guard
        let self = self,
        let text = alertController?.textFields?.first?.text
        else {
          return
      }
      
      DispatchQueue.main.async {
        let task = Task(name: text)
        
        self.taskList.append(task)
        
        let indexPath = IndexPath(row: self.taskList.count - 1, section: 0)
        
        self.tableView.beginUpdates()
        self.tableView.insertRows(at: [indexPath], with: .top)
        self.tableView.endUpdates()
      }
    }
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
    
    alertController.addAction(createAction)
    alertController.addAction(cancelAction)
    
    present(alertController, animated: true, completion: nil)
  }
}

// Mark: -Timer
extension TaskListViewController {
  func createTimer() {
    if timer == nil {
      let timer = Timer(timeInterval: 1.0,
                        target: self,
                        selector: #selector(updateTimer),
                        userInfo: nil,
                        repeats: true)
      RunLoop.current.add(timer, forMode: .common)
      timer.tolerance = 0.1
      
      self.timer = timer
    }
  }
  
  func cancelTimer() {
    timer?.invalidate()
    timer = nil
  }

  @objc func updateTimer() {
    guard let visibleRowsIndexPaths = tableView.indexPathsForVisibleRows else {
      return
    }
    
    for indexPath in visibleRowsIndexPaths {
      if let cell = tableView.cellForRow(at: indexPath) as? TaskTableViewCell {
        cell.updateTime()
      }
    }
  }
}

// Mark: - Animation
extension TaskListViewController {
  func showCongratulationAnimation() {
    // 1
    height = UIScreen.main.bounds.height + balloon.frame.size.height
    balloon.center = CGPoint(x: UIScreen.main.bounds.width / 2,
                             y: height + balloon.frame.size.height / 2)
    balloon.isHidden = false
    
    // 2
    startTime = CACurrentMediaTime()
    endTime = animationDuration + startTime!
    
    // 3
    displayLink = CADisplayLink(target: self,
                                selector: #selector(updateAnimation))
    displayLink?.add(to: RunLoop.main, forMode: .common)
  }
  
  @objc func updateAnimation() {
    guard
    let endTime = endTime,
    let startTime = startTime
      else {
        return
    }
    
    // 2
    let now = CACurrentMediaTime()
    
    if now >= endTime {
      // 3
      displayLink?.isPaused = true
      displayLink?.invalidate()
      balloon.isHidden = true
    }
    
    // 4
    let percentage = (now - startTime) * 100 / animationDuration
    let y = height - ((height + balloon.frame.height / 2) / 100 * CGFloat(percentage))
    
    // 5
    balloon.center = CGPoint(x: balloon.center.x +
      CGFloat.random(in: -0.5...0.5), y: y)
    
  }
  
  func showCongratulationsIfNeeded() {
    if taskList.filter({ !$0.completed }).count == 0 {
      cancelTimer()
      showCongratulationAnimation()
    } else {
      createTimer()
    }
  }
  
}
