(ns timelog.commands.new-task
  (:require
    [clojure.pprint :refer [pprint]]
    [clojure.string :as s]
    [promesa.core :as p]
    [timelog.commands :as cmd]
    [timelog.db :as db]))

(def statuses-p
  (p/->> (db/query {:select :*
                    :from [:statuses]
                    :order-by [:id]})
         (map (fn [status]
                [(:status status) (:id status)]))
         (into {})))

(defn create-task
  [task-name & [status]]
  (p/catch
    (p/let [statuses statuses-p
            status (or status "To Do")
            status-id (get statuses status)]
      (db/query
        {:insert-into :tasks
         :columns [:task_name :status_id]
         :values [[task-name status-id]]})
      (println (str "Created task \"" task-name "\" in \"" status "\"")))
    (fn [err]
      (js/console.error err))))

(def rules
  [{:tests   [(fn [[task-name _status]]
               (and (string? task-name)
                    (not (s/blank? task-name))))]
    :message "Task name must be a string"}


   {:tests [(fn [[_task-name status]]
              (or (nil? status)
                  (contains? #{"To Do"
                               "Deferred"
                               "In Progress"
                               "Complete"
                               "Archived"}
                             status)))]
    :message "Status must be omitted or a known status"}])

(defn validator
  [args]
  (doseq [{:keys [tests message]} rules]
    (when (not (every-pred tests args))
      (throw (js/Error. (str "ValidationError: " message)))))
  true)

(cmd/register!
  :new
  {:args      [:name :status]
   :validator validator
   :cmd       create-task})
