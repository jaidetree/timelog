(ns timelog.commands.start-task
  (:require
    [clojure.pprint :refer [pprint]]
    [promesa.core :as p]
    [timelog.db :as db]
    [timelog.commands :as cmd]))

(defn validator
  [[task-name]]
  (string? task-name))

(defn start-task
  [task-name]
  (p/-> (db/query
          {:select :*
           :from [[[:start_task task-name]]]})
        (clj->js)
        (js/JSON.stringify nil 2)
        (js/console.log)))

(cmd/register!
  :start
  {:args [:task-name]
   :validator validator
   :cmd start-task})

