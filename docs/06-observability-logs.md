# 06. Observability поверх логов (Dashboards + Alerts)

На данном этапе добавляем “операторский” слой поверх Loki:

- готовые Grafana dashboards для просмотра логов
- алерты по ошибкам в логах через Loki Ruler → Alertmanager

---

## Dashboards

Dashboards добавляются декларативно через ConfigMap с label:

```yaml
grafana_dashboard: "1"
