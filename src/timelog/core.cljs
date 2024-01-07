(ns timelog.core
  (:require
    ["dotenv/config"]
    [clojure.pprint :refer [pprint]]
    [promesa.core :as p]
    [timelog.db :as db]))

(defn ls
  []
  (p/-> (db/query
          {:select [:*]
           :from [:tasks]
           :where [:and [:= :is_active true]
                        [:not= :status_id 5]]
           :order-by [:status_id]})
        (pprint)))

(defn new-task
  [task-name & [status]])

(defn start-task
  [task-name])

(defn stop-task
  [])

(defn status
  [])


(defn -main
  [cmd & args]
  (p/do
    (case (keyword cmd)
     :ls (ls)
     :new (apply new-task args)
     :start (apply start-task args)
     :stop  (stop-task)
     :status (status))
    (db/close!)))

