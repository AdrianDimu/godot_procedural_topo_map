extends Node
class_name ThreadPool

const MAX_THREADS := 6
const RESERVED_FOR_MAIN := 1

var active_threads: Array[Thread] = []
var task_queue: Array = []

func request_thread(target: Object, method: String, userdata = null) -> void:
	call_deferred("_deferred_cleanup")
	if active_threads.size() < (MAX_THREADS - RESERVED_FOR_MAIN):
		_run_thread(target, method, userdata)
	else:
		task_queue.append({ "target": target, "method": method, "userdata": userdata })

func _deferred_cleanup():
	cleanup()

func _run_thread(target: Object, method: String, userdata) -> void:
	var t = Thread.new()
	var err = t.start(Callable(target, method).bind(userdata))
	if err == OK:
		active_threads.append(t)

func cleanup():
	var still_alive: Array[Thread] = []
	for t in active_threads:
		if t.is_alive():
			still_alive.append(t)
		else:
			t.wait_to_finish()
	active_threads = still_alive
	call_deferred("_run_next_task")

func _run_next_task():
	if active_threads.size() < (MAX_THREADS - RESERVED_FOR_MAIN) and task_queue.size() > 0:
		var job = task_queue.pop_front()
		_run_thread(job.target, job.method, job.userdata)
		if task_queue.size() > 0:
			await get_tree().create_timer(0.03).timeout
			call_deferred("_run_next_task")

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		cleanup()
		for t in active_threads:
			t.wait_to_finish()
