(ns timelog.commands.status
  (:require
    [clojure.pprint :refer [pprint]]
    [promesa.core :as p]
    [timelog.db :as db]
    [timelog.commands :as cmd]))

(defn status
  []
  (p/-> (db/query
          {:select [:t.* :s.status :se.start_time [:se.id :session_id]]
           :from [[:tasks :t]]
           :join-by [:join [[:statuses :s]
                            [:= :t.status_id :s.id]]
                     :join [[:sessions :se]
                            [:= :t.id :se.task_id]]]
           :where [:and [:= :t.is_active true]
                        [:not= :s.status "Archived"]
                        [:not= :s.status "Deferred"]
                        [:is :se.end_time :null]]
           :order-by [[:se.start_time :desc]]
           :limit 1})
        (clj->js)
        (js/JSON.stringify nil 2)
        (js/console.log)))

(cmd/register!
  :status
  {:args []
   :validator (constantly true)
   :cmd status})

