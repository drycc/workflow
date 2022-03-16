{{/* Generate common affinity */}}
{{- define "common.affinity" }}
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      podAffinityTerm:
        labelSelector:
          matchExpressions:
          - key: {{ .key }}
            operator: In
            values:
            {{- range .values }}
            - {{ . | quote }}
            {{- end }}
        topologyKey: topology.kubernetes.io/zone
    - weight: 90
      podAffinityTerm:
        labelSelector:
          matchExpressions:
          - key: {{ .key }}
            operator: In
            values:
            {{- range .values }}
            - {{ . | quote }}
            {{- end }}
        topologyKey: kubernetes.io/hostname
{{- end }}