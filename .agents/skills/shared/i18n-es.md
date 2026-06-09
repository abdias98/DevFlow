# i18n — Español (Spanish)

Traducciones de referencia para mensajes y prompts de usuario en DevFlow. Los agentes detectan el idioma del usuario y adaptan sus respuestas. Este archivo proporciona las traducciones canónicas de términos y frases clave.

## Regla de detección

Si el usuario escribe en español → responder en español. Si escribe en inglés → responder en inglés. Los templates y mensajes fijos se adaptan al idioma detectado.

## Términos del framework

| English | Español |
|---------|---------|
| Orchestrator | Orquestador |
| Brainstormer | Analista |
| Architect | Arquitecto |
| Planner | Planificador |
| Implementer | Implementador |
| Reviewer | Revisor |
| Debugger | Depurador |
| Finalizer | Finalizador |
| Feature Agent | Agente de Features |
| Bug-Fixer | Corrector de Bugs |
| Refactorer | Refactorizador |
| Performance Agent | Agente de Rendimiento |

## Fases del ciclo

| English | Español |
|---------|---------|
| Phase 1: Brainstormer | Fase 1: Comprensión del problema |
| Phase 2: Architect | Fase 2: Diseño de arquitectura |
| Phase 3: Planner | Fase 3: Plan de implementación |
| Phase 5: Implementer | Fase 5: Implementación (TDD) |
| Phase 5: Reviewer | Fase 5: Revisión de código |
| Phase 6: Debugger | Fase 6: Depuración |
| Phase 7: Finalizer | Fase 7: Finalización |
| Confirmation Gate | Puerta de Confirmación |

## Mensajes de confirmación

| English | Español |
|---------|---------|
| Plan + Test Cases + Mockups complete. Review the plan — proceed to Implementation? | Plan + Casos de Prueba + Mockups completos. ¿Revisar el plan y proceder a Implementación? |
| Yes — proceed | Sí — proceder |
| Request changes | Solicitar cambios |
| Cancel | Cancelar |
| Approve | Aprobar |
| Standard — auto-complete all tasks | Estándar — auto-completar todas las tareas |
| Pair — review after each task | En pareja — revisar después de cada tarea |

## Mensajes de preguntas (Brainstormer)

| English | Español |
|---------|---------|
| What is the primary outcome? | ¿Cuál es el resultado principal? |
| What does "done" look like? | ¿Cómo se ve "terminado"? |
| What is explicitly in scope and out of scope? | ¿Qué está dentro y fuera del alcance? |
| Invalid, empty, or unexpected input behavior? | ¿Comportamiento ante entrada inválida, vacía o inesperada? |
| How to verify it works? | ¿Cómo verificar que funciona? |
| Does this change existing behavior? | ¿Esto modifica comportamiento existente? |

## Estados y severidades

| English | Español |
|---------|---------|
| BLOCK | BLOQUEO |
| WARN | ADVERTENCIA |
| INFO | INFORMACIÓN |
| APPROVED | APROBADO |
| CHANGES REQUESTED | CAMBIOS SOLICITADOS |
| PENDING | PENDIENTE |
| DONE | COMPLETADO |
| FAIL | FALLÓ |
| PASS | PASÓ |

## Mensajes del Orchestrator

| English | Español |
|---------|---------|
| A DevFlow cycle is in progress at Phase {N} for '{slug}'. Continue or start a new cycle? | Hay un ciclo DevFlow en progreso en la Fase {N} para '{slug}'. ¿Continuar o iniciar uno nuevo? |
| Plan complete. Handing back to the Orchestrator for confirmation. | Plan completo. Devolviendo el control al Orquestador para confirmación. |
| Implementation complete. All tasks done. Invoking code review... | Implementación completa. Todas las tareas finalizadas. Invocando revisión de código... |
| Cycle complete. | Ciclo completado. |
| Session memory cleaned. Feature is ready. | Memoria de sesión limpiada. Feature lista. |

## Notas de uso

1. Los agentes leen este archivo cuando detectan español como idioma del usuario.
2. Las traducciones son referencia — el agente puede adaptar el tono y vocabulario al contexto.
3. Los términos técnicos (TDD, BLOCK, WARN, API, etc.) se mantienen en inglés cuando son parte del framework.
4. Los templates internos (specs, plans, reviews) mantienen sus secciones en inglés ya que son artefactos técnicos.
5. Nuevas traducciones se agregan a este archivo según necesidad.
