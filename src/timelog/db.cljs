(ns timelog.db
  (:require
    [clojure.pprint :refer [pprint]]
    [promesa.core :as p]
    [honey.sql :as sql]
    ["fs" :as fs]
    ["pg$default" :as pg]))

(def Pool (.-Pool pg))

(def cfg (clj->js {:connectionString js/process.env.DATABASE_URL
                   :ssl {:require true
                         :rejectUnauthorized false}}))

(def pool (new Pool cfg))

(defn query
 [sqlmap]
 (let [[sql-str & args] (sql/format sqlmap {:inline true})]
   (p/-> (.query pool sql-str (clj->js args))
         (.-rows)
         (js->clj :keywordize-keys true))))

(defn -main
  []
  (p/catch (p/let [result (query {:select [:*]
                                  :from [:statuses]})]
             (pprint result)
             (.end pool))
    js/console.error))

(defn close!
  []
  (.end pool))
