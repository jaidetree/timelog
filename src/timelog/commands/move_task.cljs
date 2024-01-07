(ns timelog.commands.move-task)

;; - Usage timelog move "Fix the list command" complete
;; - If the task is in progress, the target is complete, and has an open session
;;   end the session) and move the task to completed
;; - If there is an open session for the task, prevent moving it
