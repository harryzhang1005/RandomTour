//
//  GCDQueues.swift
//
//  Created by Harvey Zhang on 1/13/16.
//  Copyright © 2016 HappyGuy. All rights reserved.
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
	class var GlobalMainQueue: DispatchQueue {
		return DispatchQueue.main
	}
	
	class var GlobalUserInteractiveQueue: DispatchQueue {
		return DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive)
	}
	
	class var GlobalUserInitiatedQueue: DispatchQueue {
		return DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated)
	}
	
	class var GlobalUtilityQueue: DispatchQueue {
		return DispatchQueue.global(qos: DispatchQoS.QoSClass.utility)
	}
	
	class var GlobalBackgroundQueue: DispatchQueue {
		return DispatchQueue.global(qos: DispatchQoS.QoSClass.background)
	}
	
}//EndClass
