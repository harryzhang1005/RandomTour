//
//  GCDQueues.swift
//

import Foundation

class GCDQueues: NSObject
{

/**
  * @param identifier
  * A quality of service class defined in qos_class_t or a priority defined in
  * dispatch_queue_priority_t.
  *
  * It is recommended to use quality of service class values to identify the
  * well-known global concurrent queues:
  *  - QOS_CLASS_USER_INTERACTIVE
  *  - QOS_CLASS_USER_INITIATED
  *  - QOS_CLASS_DEFAULT
  *  - QOS_CLASS_UTILITY
  *  - QOS_CLASS_BACKGROUND
  *
  * The global concurrent queues may still be identified by their priority,
  * which map to the following QOS classes:
  *  - DISPATCH_QUEUE_PRIORITY_HIGH:         QOS_CLASS_USER_INITIATED
  *  - DISPATCH_QUEUE_PRIORITY_DEFAULT:      QOS_CLASS_DEFAULT
  *  - DISPATCH_QUEUE_PRIORITY_LOW:          QOS_CLASS_UTILITY
  *  - DISPATCH_QUEUE_PRIORITY_BACKGROUND:   QOS_CLASS_BACKGROUND
  */

  // Get standard 5 queues (4 global concurrent queue + 1 main serial queue)
  class var GlobalMainQueue: dispatch_queue_t {
    return dispatch_get_main_queue()
  }
  
  class var GlobalUserInteractiveQueue: dispatch_queue_t {
    return dispatch_get_global_queue(Int(QOS_CLASS_USER_INTERACTIVE.rawValue), 0)
  }
  
  class var GlobalUserInitiatedQueue: dispatch_queue_t {
    return dispatch_get_global_queue(Int(QOS_CLASS_USER_INITIATED.rawValue), 0)
  }
  
  class var GlobalUtilityQueue: dispatch_queue_t {
    return dispatch_get_global_queue(Int(QOS_CLASS_UTILITY.rawValue), 0)
  }
  
  class var GlobalBackgroundQueue: dispatch_queue_t {
    return dispatch_get_global_queue(Int(QOS_CLASS_BACKGROUND.rawValue), 0)
  }
  
}//EndClass
