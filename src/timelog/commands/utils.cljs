(ns timelog.commands.utils)

(def a-spec
  {:test      string?
   :coerce    js/String
   :message   "Input must be a string"
   :optional  true})

(defn pred->spec
  [pred-fn & {:keys [optional message]}]
  {:test pred-fn
   :message message
   :optional (true? optional)})

(defn input->state
  [input]
  {:input input
   :output output
   :path  []
   :valid true})

(defn check
  [spec input]
  (let [state (input->state input)]))


;; @TODO: Replace with reducer or loop to apply each transform
;;        Transform can be used to modify values
(defn validate-rules
   [rules args]
   (doseq [{:keys [tests message]} rules]
     (when (not (every-pred tests args))
       (throw (js/Error. (str "ValidationError: " message))))))

(fn [])

(defn validate-rules2
  [rules values]
  (loop [rules rules
         args args]
    (let [[rule ...rules] rules]
      (if rule
        (->> (:tests rule)
             (loop
               (fn [[args ret] test-fn]
                 (test-fn args))))))))

