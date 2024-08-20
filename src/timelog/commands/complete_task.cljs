(ns timelog.commands.complete-task
  (:require
    [clojure.pprint :refer [pprint]]
    [clojure.string :as s]
    [promesa.core :as p]
    [timelog.commands :as cmd]
    [timelog.db :as db]))

(defn complete-task
  [task-name]
  (p/->
    (db/query {:select :*
               :from [[[:complete_task task-name]]]
               :order-by [:id]})
    (p/catch js/console.error)
    (clj->js)
    (js/JSON.stringify nil 2)
    (js/console.log)))


(def rules
  [{:tests   [(fn [[task-name _status]]
               (and (string? task-name)
                    (not (s/blank? task-name))))]
    :message "Task name must be a string"}])


(defn validator
  [args]
  (validate-rules rules args)
  true)

(cmd/register!
  :complete
  {:args      [:name]
   :validator validator
   :cmd       complete-task})

;; - Usage timelog move "Fix the list command" complete
;; - If the task is in progress, the target is complete, and has an open session
;;   end the session) and move the task to completed
;; - If there is an open session for the task, prevent moving it
