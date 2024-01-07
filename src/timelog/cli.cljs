(ns timelog.cli
  (:require
    ["dotenv/config"]
    [promesa.core :as p]
    [timelog.db :as db]
    [timelog.commands :as cmd]
    [timelog.commands.list]
    [timelog.commands.new-task]))

(defn -main
  [cmd & args]
  (let [cmdname (keyword cmd)]
    (p/do
      (if-let [{:keys [validator f]} (cmd/get cmdname)]
        (if (validator args)
          (apply f args)
          (cmd/help))
        (cmd/help))
      (db/close!))))

