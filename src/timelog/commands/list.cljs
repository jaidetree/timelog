(ns timelog.commands.list
  (:require
    [clojure.pprint :refer [pprint]]
    [promesa.core :as p]
    [timelog.commands :as cmd]
    [timelog.db :as db]))

(defn group-tasks-by-status
  [tasks]
  (->> tasks
       (group-by :status_id)))

(defn print-tasks
  [groups]
  (doseq [[id tasks] groups]
    (println (:status (first tasks)))
    (doseq [t tasks]
      (println (str "  " (:id t) " - " (:task_name t))))
    (println "")))

(defn list-tasks
  []
  (p/-> (db/query
          {:select [:*]
           :from [[:tasks :t]]
           :join-by [:join [[:statuses :s]
                            [:= :s.id :t.status_id]]]
           :where [:and [:= :t.is_active true]
                        [:not= :s.status "Archived"]
                        [:not= :s.status "Deferred"]]
           :order-by [:status_id]})
        (group-tasks-by-status)
        (print-tasks)))


(cmd/register!
  :ls
  {:args      []
   :validator (constantly true)
   :cmd       list-tasks})
