(ns timelog.commands.stop-task
  (:require
    [clojure.pprint :refer [pprint]]
    [promesa.core :as p]
    [timelog.db :as db]
    [timelog.commands :as cmd]))

(defn validator
  [[task-name]]
  (string? task-name))

(defn stop-task
  [task-name]
  (p/-> (db/query
          {:select :*
           :from [[[:stop_task task-name]]]})
        (pprint)))

(cmd/register!
  :stop
  {:args [:task-name]
   :validator validator
   :cmd stop-task})

