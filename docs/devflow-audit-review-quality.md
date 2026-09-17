# DevFlow — Auditoría de calidad de revisión y aplicación de estándares

> **Fecha:** 2026-09-16 · **Base auditada:** `937d38a` — `chore(release): 4.10.0 — KISS as the fifth design principle (F64)` (rama `chore/release-4.10.0`)
> **Alcance:** la cadena completa de verificación (Critical Friend → Validation Gate → Task Supervisor → Verifier → Reviewer), los 16 estándares de ingeniería, `standards-quick-card.md`, `review-checklist.md`, los templates de spec / plan / feature, las reglas del Implementer, `rules.md` (severidades y Critical Friend) y los templates de referencia de `shared/templates/`.
> **Método:** lectura íntegra de los documentos de verificación y revisión; lectura de los estándares con foco en *cómo se aplican* (quién los carga, cuándo, con qué severidad); cruce de las severidades entre estándar, checklist y Quick Card; y una pregunta guía distinta a la de auditorías anteriores — **no "¿está bien escrito?", sino "¿qué clase de defecto no tiene a nadie encargado de encontrarlo?"**.
> **Continuación de:** `docs/devflow-audit-main.md` (F01–F46) y Waves 15–17 (F47–F64). Numeración nueva: **F65–F96**.

---

## 0. Resumen ejecutivo

**Línea base verificada hoy:** `bash scripts/validate-framework.sh` → *Validation passed — framework is consistent ✓*. `bats tests/` → **149/149 OK**. Ninguno de los hallazgos de este informe es detectable por ese tooling: son problemas de *diseño del proceso de verificación*, no de consistencia estructural.

**Síntoma observado en uso real:** al llegar al PR, un agente revisor externo encuentra sistemáticamente correcciones que la cadena de DevFlow dejó pasar, y una parte de ellas son defectos funcionales visibles. El síntoma no apunta a un estándar concreto sino a **clases enteras de defecto sin responsable**.

Cinco bloques:

1. **La revisión verifica cumplimiento, no corrección (§1).** Las tres dimensiones del Reviewer (Seguridad, Performance/Concurrencia, Arquitectura/Calidad/Plan) contrastan código contra reglas. Ninguna razona sobre *qué hace el código en ejecución*. Y `rules.md` lo refuerza: *"Opinions without citations are not challenges; they are preferences"* — un defecto funcional que no viola una sección de un estándar **no puede reportarse**. El revisor externo no tiene esa restricción; por eso ve lo que DevFlow no.
2. **Toda la cadena de verificación está anclada al plan (§2).** Task Supervisor, Verifier y la dimensión 3 del Reviewer miden "cumplimiento del plan". Los tests también salen del plan. Si el plan omitió un escenario, cada capa lo aprueba de forma coherente. Un revisor sin plan no hereda esa ceguera.
3. **Los estándares se aplican tarde (§3).** El Quick Card solo lista disparadores BLOCK; los agentes que escriben código cargan el estándar completo *solo si* hay una alerta. Los principios de diseño (SRP, OCP, SoC, DRY, KISS) son WARN/INFO, no están en el Quick Card, y por tanto no se cargan mientras se diseña ni mientras se implementa: se descubren en la revisión, o en el PR.
4. **La severidad tiene dos fuentes de verdad y un hueco (§4).** `review-checklist.md` redefine severidades que ya contradicen a los estándares, y la taxonomía de `rules.md` no tiene categoría para un defecto funcional.
5. **Cobertura y calibración (§5, §6).** Faltan dominios transversales completos (estado/ciclo de vida de datos, persistencia, consumo de integraciones, patrones tácticos) y no existe ningún mecanismo que mida cuánto se escapa al PR ni en qué capa debió detectarse.

**Priorización:** 8 P0 · 15 P1 · 9 P2 (32 hallazgos, F65–F96). El catálogo atómico con criterios de aceptación vive en `docs/implementation-plan-waves-18-21.md`.

> **Principio rector de este informe.** Ninguna propuesta se diseña alrededor de un bug concreto. Cada hallazgo describe una *clase* de defecto y la *capa* que debería detectarla. Los ejemplos observados en uso real se usan solo como validación posterior (§6.3), nunca como especificación.

---

## 1. La revisión verifica cumplimiento, no corrección

### 1.1 Las dimensiones del Reviewer son todas de cumplimiento — **P0 (F65)**

`devflow-review/SKILL.md` Step 3 despacha tres subagentes:

| Subagente | Lente | Pregunta implícita |
|---|---|---|
| 1 — Security & Safety | `security.md`, `error-handling.md` | ¿viola una regla de seguridad? |
| 2 — Performance & Concurrency | `performance.md`, `concurrency.md` | ¿viola una regla de rendimiento? |
| 3 — Architecture, Quality & Plan Compliance | 9 estándares + spec/plan | ¿viola una regla de diseño o se aparta del plan? |

Clases de defecto que **ninguna** dimensión tiene encargadas:

| Clase | Descripción genérica |
|---|---|
| **Lógica** | condición invertida, límite mal calculado, rama no alcanzable, caso no manejado |
| **Transiciones de estado** | el resultado depende de la secuencia de eventos (cambio de entrada, repetición, orden, reentrada) y no solo del estado final |
| **Efectos secundarios** | trabajo que se ejecuta de más, de menos, o en el momento equivocado (peticiones, escrituras, suscripciones, temporizadores) |
| **Contrato con el llamador** | el cambio es correcto en sí mismo pero rompe una expectativa de quien lo usa |
| **Datos límite** | vacío, nulo, un elemento, muchos, duplicados, valores fuera de rango |
| **Fallos parciales** | qué queda visible o persistido si una parte falla a mitad |

Son exactamente las clases que un revisor humano o un agente de PR busca primero, y en DevFlow no tienen dueño.

### 1.2 La regla de citación prohíbe reportar lo que no está en un estándar — **P0 (F66)**

`shared/rules.md:111` (Critical Friend Principle, regla 6):

> *"Every challenge MUST reference the specific standard and section that is violated. Opinions without citations are not challenges; they are preferences."*

`devflow-review/SKILL.md:20` y la síntesis (Step 3 → Synthesis, punto 4) exigen lo mismo para **cada hallazgo**: `{standard}.md §{N} → {BLOCK|WARN|INFO}`.

La regla nació para evitar objeciones de gusto (correcto), pero aplicada a la revisión tiene un efecto no intencionado: **un defecto funcional demostrable no tiene sección que citar**, así que el Reviewer lo descarta o lo degrada a una "preferencia". La corrección no es eliminar la citación, sino aceptar una segunda forma de evidencia: **un escenario reproducible** (entrada/secuencia → resultado observado → resultado esperado) vale tanto como una cita.

### 1.3 La taxonomía de severidad no tiene lugar para un defecto funcional — **P0 (F67)**

`rules.md:358` define BLOCK como *"Security vulnerability, data-loss risk, or architectural violation contradicting a core standard"*. Cada estándar tiene su propia tabla de severidad, pero ninguna regla transversal dice qué severidad tiene *"el sistema hace algo observablemente incorrecto para el usuario"*. En la práctica, los estándares de diseño (`design-principles.md` §7 declara explícitamente *"none by default"* para BLOCK) y de UI (`ui-design.md` §16: un único BLOCK, secreto en plantilla) dejan esa clase sin techo.

Falta una regla de severidad **independiente de estándar**, basada en impacto observable:

| Impacto | Severidad propuesta |
|---|---|
| Resultado incorrecto visible, datos de un contexto mostrados en otro, pérdida o corrupción de datos, requisito de la DoD incumplido | BLOCK |
| Trabajo redundante o innecesario con coste real, degradación en un caso secundario, estado inconsistente recuperable | WARN |
| Robustez mejorable sin fallo demostrable | INFO |

### 1.4 El Reviewer solo lee los archivos cambiados — **P1 (F68)**

Step 3: *"Each subagent reads the complete changed files (not just diff)"*. Muchos defectos viven en la **relación** entre un archivo cambiado y uno que no cambió: quien lo invoca, quien consume su salida, quien comparte su estado. La Impact Zone (`devflow-ctl scope impact`) ya calcula exactamente ese conjunto, pero se usa solo para control de alcance (`scope audit`), nunca como contexto de lectura de la revisión.

### 1.5 Nadie evalúa si los tests detectarían un defecto — **P1 (F69)**

`testing.md` §10 y `review-checklist.md` → Test Coverage verifican *existencia* (happy path, un edge case, un error; "all tasks have tests"). Nadie pregunta *"si introduzco un defecto plausible en esta línea, ¿qué test falla?"* (razonamiento de mutación). Un conjunto de tests puede cumplir el checklist y no proteger ningún comportamiento relevante.

### 1.6 El subagente 3 está sobrecargado — **P1 (F70)**

Una sola pasada carga SOLID, Clean Architecture, Testing, Project Design, REST API, UI Design, Accessibility, Logging, Dependencies **y** el cruce con spec/plan. Los subagentes 1 y 2 tienen dos estándares cada uno. La atención se reparte de forma muy desigual: los dominios que caen al final de la lista del subagente 3 (UI, accesibilidad, logging, dependencias) reciben la revisión más superficial.

### 1.7 Nadie compara con implementaciones hermanas — **P2 (F71)**

El Planner fija una *Reference implementation* por tarea (`plan-template.md`) y `project-design.md` §6 tiene un WARN para *"new code fights the existing architectural pattern"*, pero ninguna capa lee la implementación de referencia y la compara con la nueva: convenciones de manejo de estado, errores, carga de datos, nombres y estructura del mismo tipo de artefacto en el proyecto.

---

## 2. La cadena de verificación está anclada al plan

### 2.1 Tres capas, una misma fuente de verdad — **P0 (F72)**

| Capa | Documento | Qué compara |
|---|---|---|
| Task Supervisor | `task-supervisor.md` §axes | implementación ↔ *acceptance criteria* del work packet |
| Verifier | `verifier-subagent.md` §2 | implementación ↔ File Map, tareas, entregables del plan |
| Reviewer, subagente 3 | `devflow-review/SKILL.md` Step 3 | implementación ↔ spec + plan |

Las tres son valiosas y deben seguir existiendo, pero comparten un modo de fallo: **si el plan es incompleto, las tres aprueban de forma consistente.** Ninguna tiene el mandato de mirar el código *sin* haber leído el plan primero. El agente de PR externo revisa en esas condiciones —sin plan— y por eso no hereda la omisión.

Propuesta: la dimensión de corrección (F65) ejecuta una **primera pasada ciega** (código + consumidores, sin spec ni plan), anota sus hallazgos, y solo después contrasta con el plan para clasificarlos: *defecto de implementación* (el plan lo cubría) o *hueco del plan* (el plan no lo cubría → se enruta al Planner, ruta que la tabla de Step 5 ya prevé).

### 2.2 Los tests heredan el modelo mental del plan — **P0 (F73)**

`plan-template.md` escribe los tests de cada tarea (✅ happy path, ⚠️ edge case, ❌ failure) **antes** del código, en la misma fase que diseña la solución. El Implementer luego escribe *"minimal code to pass tests — nothing more, nothing less"* (`devflow-implement/SKILL.md:23`). Con TDD, un escenario que el Planner no imaginó no tiene test y, por diseño, el código tampoco lo maneja: TDD **garantiza** la omisión en lugar de mitigarla.

El requisito de tests es además **por unidad** (una tarea, un archivo). No existe un paso que derive escenarios de comportamiento a nivel de *feature*: secuencias de eventos, cambios de contexto, repeticiones, interacción entre componentes.

`traceability-matrix.md` ya mapea DoD y Edge Cases a tests, pero sus filas salen de `context.md` → Edge Cases, que el Brainstormer define como *"Invalid, empty, or unexpected input"* (`devflow-brainstorm/questions-template.md`): entradas, no transiciones.

### 2.3 Las reglas del Implementer desalientan manejar casos no previstos — **P1 (F74)**

`devflow-implement/SKILL.md:23-24,28-33`: *"minimal code"*, *"follow the plan step by step"*, *"NEVER add features not in the plan"*, y cualquier desviación requiere aprobación del usuario. La intención (evitar scope creep) es correcta, pero la redacción no distingue entre **añadir funcionalidad** (prohibido) y **manejar un caso del comportamiento ya pedido** que el plan olvidó (obligatorio). Un Implementer obediente deja el hueco abierto sin avisar.

### 2.4 El Verifier y el Task Supervisor excluyen explícitamente el razonamiento funcional — **P2 (F75)**

`verifier-subagent.md` Anti-Patterns: *"❌ Verifier does deep quality review — that is the Reviewer's job"*; su eje 4 ("Obvious issues") se limita a sintaxis, imports rotos y TODOs. La separación es correcta, pero combinada con §1.1 deja a la corrección funcional **sin ninguna capa**. Basta con que el Verifier añada un eje barato y acotado: *"¿cada criterio de aceptación tiene un camino de código que lo produce, y hay algún camino que lo contradiga?"*.

### 2.5 No hay verificación en ejecución — **P2 (F76)**

La única verificación que mira el sistema funcionando es el *visual diff* (`vision-verification.md`), que compara una captura con el mockup: aspecto, no comportamiento. Cuando el entorno lo permite (terminal, navegador automatizable, servidor de desarrollo), falta un paso opcional que **ejecute los escenarios** derivados en F73 y observe salidas, logs, consola y tráfico de red. Debe degradar con elegancia según `environment-probe.md`, igual que vision.

---

## 3. Los estándares se aplican tarde

### 3.1 El Quick Card solo conoce BLOCKs, y es la puerta de todo lo demás — **P0 (F77)**

`standards-quick-card.md` se describe como *"the most critical BLOCK triggers only"*. La política de carga *"scan first, load on demand"* —usada por Implementer (`:14`), Planner (`:14`), Feature Agent, Critical Friend (`critical-friend.md:17`) y los subagentes del Reviewer (`devflow-review/SKILL.md:90`)— carga el estándar completo **solo si** una alerta del Quick Card coincide.

Consecuencia: todo lo que es WARN o INFO queda fuera del radar mientras se escribe código. Eso incluye casi todo el diseño:

| Estándar | BLOCKs en Quick Card | Reglas relevantes que nunca se cargan por esta vía |
|---|---|---|
| `design-principles.md` | 0 (todo WARN) | DRY, YAGNI, SoC, agnosticismo, KISS |
| `solid.md` | 2 (LSP, DIP en dominio) | SRP, OCP, ISP |
| `ui-design.md` | 1 (secreto en plantilla) | componentes, estados de interacción, formularios, rendimiento |
| `testing.md` | 3 | aislamiento, anatomía, qué mockear |
| `project-design.md` | 2 | god objects, dumping grounds, pelear contra el patrón existente |

Las correcciones "de calidad" que aparecen en el PR pertenecen mayoritariamente a esta franja.

### 3.2 La política de carga del Reviewer se contradice — **P0 (F78)**

- `devflow-review/SKILL.md:14` (Rules): *"scan first, then load **every** domain in scope … thoroughness first"*.
- `devflow-review/SKILL.md:90` (Step 3): *"quick-card gate … Only if a red flag matches … does the subagent load the full standard. This saves ~60-80%"*.
- `devflow-review/SKILL.md:77` (Skip criteria): revisión inline si 1-2 archivos y cambios "mecánicos" — juicio que hace el propio agente.
- Standalone Mode Step 1.5 (`:168-170`): *"Always: SOLID, Clean Architecture, Security, Performance, Project Design Patterns"* — **omite** `design-principles.md`, `testing.md`, `error-handling.md`, `logging.md`, `concurrency.md`, `dependencies.md` y `git-conventions.md`, que el modo ciclo sí lista. Los flujos standalone (feature, bug-fix, refactor) son los de mayor uso.

Cuatro reglas distintas para la misma decisión. La más restrictiva gana en la práctica.

### 3.3 Los estándares están escritos para revisar, no para diseñar — **P1 (F79)**

Estructura obligatoria de un estándar (`validate-framework.sh` §12.3): *Severity Classification*, *Code Review Checklist*, *Applying This Standard with a Limited Scope*. No existe un equivalente para las fases que producen el código:

- **Diseño** (Architect): *qué decisiones debe tomar y dejar explícitas la spec* respecto a este dominio.
- **Implementación** (Implementer): *qué comprobar antes de dar una tarea por terminada*.

El resultado es que el Architect lee 14 estándares (`devflow-architect/SKILL.md:14-27`) sin un formato que le diga qué producir con ellos.

### 3.4 La spec y el plan no dejan constancia de cómo se aplicaron — **P1 (F80)**

`spec-template.md` tiene una única sección de aplicación explícita de un estándar: *Concurrency Strategy*. No hay equivalente para manejo de errores, estado, seguridad, patrones de diseño elegidos, etc. `plan-template.md` tampoco lleva restricciones de estándares en el work packet (el Planner *"cite the specific section for any standard-driven task constraint"* es opcional en la práctica). Como los subagentes de tarea del Implementer tienen prohibido leer nada fuera de su work packet (`devflow-implement/SKILL.md:95`), **las decisiones de estándares que no están en el work packet no llegan a quien escribe el código**.

### 3.5 No hay puente entre el estándar agnóstico y el stack concreto — **P1 (F81)**

Los estándares son deliberadamente agnósticos (correcto). Pero nada traduce *"SoC"*, *"SRP"* o *"libera recursos"* a lo que significan en el stack del proyecto: dónde vive la lógica, cómo se modela el estado, qué primitiva de cancelación/limpieza usa el framework, cuál es el patrón de carga de datos del proyecto. `shared/templates/*.md` contienen parte de ese conocimiento (p. ej. *State Categories* y *Common Anti-Patterns* en `web-frontend.md`), pero son guías de referencia que solo lee el Architect, sin severidades y sin enlace desde los estándares. Sin ese puente, el modelo aplica las reglas de forma superficial y genérica.

---

## 4. Severidad: dos fuentes de verdad

### 4.1 `review-checklist.md` redefine severidades y ya contradice a los estándares — **P1 (F82)**

`review-checklist.md` contiene **17** marcadores 🔴 BLOCK propios. Algunos divergen de su estándar canónico:

| Regla | `review-checklist.md` | Estándar canónico |
|---|---|---|
| Responsabilidad única en componente | 🔴 BLOCK (`:10`) | `solid.md` §8 → SRP = **WARN** |
| Modal inline dentro del componente que lo abre | 🔴 BLOCK (`:67`) | `ui-design.md` §16 → sin trigger equivalente |
| Falta validación de entrada en frontera | 🔴 BLOCK (`:20`) | `security.md` → coincide |

Viola la propia `standards-dry-policy.md` (una regla, un dueño). El checklist debe **referenciar** las tablas de severidad, no restatearlas.

### 4.2 Criterios de "cambio mecánico" autoevaluados — **P2 (F83)**

Los criterios de omisión (Reviewer inline, Verifier, Task Supervisor) dependen de juicios como *"changes are mechanical"* o *"no performance-sensitive code"* que realiza el mismo agente que produjo el cambio. Deben basarse en señales verificables del diff (número de archivos, presencia de ramas condicionales nuevas, efectos secundarios nuevos, archivos de estado/servicios tocados), y un cambio que añade lógica condicional o efectos nunca debe calificar como mecánico.

---

## 5. Cobertura de dominios y patrones

### 5.1 Mapa de cobertura por capa — **P1 (F84, F85, F86)**

Cruce de los 16 estándares con las capas de una aplicación típica:

| Capa | Estándares que la cubren | Estado |
|---|---|---|
| Presentación (aspecto, accesibilidad) | `ui-design`, `accessibility` | ✅ |
| **Estado y ciclo de vida de datos** (stores, cachés, sesiones, estado derivado, invalidación, suscripciones, limpieza) | parcial: `performance` §3 (caché servidor), `concurrency` §7 (procesos) | ❌ **sin dueño** (F84) |
| **Consumo de integraciones** (lado cliente de una API/servicio: timeouts, reintentos, cancelación, respuestas fuera de orden, estados parciales) | parcial: `error-handling` §8, `performance` §4 | ❌ **sin dueño** (F85) |
| Exposición de API | `rest-api` | ✅ |
| Dominio / aplicación | `solid`, `clean-architecture`, `design-principles` | ✅ |
| **Persistencia y modelado de datos** (esquema, migraciones, integridad referencial, transacciones, índices) | parcial: `performance` §2, `error-handling` §6 | ❌ **sin dueño** (F86) |
| Mensajería | `event-driven-architecture` | ✅ |
| Transversal | `security`, `logging`, `error-handling`, `concurrency`, `dependencies`, `testing`, `git-conventions`, `project-design` | ✅ |

Las tres capas sin dueño son precisamente las que concentran defectos de comportamiento, porque su corrección depende del tiempo y la secuencia, no de la forma del código. Cada estándar nuevo debe ser **agnóstico de tecnología** (web, móvil, escritorio, backend) como el resto.

### 5.2 Patrones tácticos sin guía — **P1 (F87)**

`project-design.md` cubre la elección de **arquitectura** (capas, feature folders, detectar-evaluar-actuar). Los patrones tácticos (Strategy, Factory, Adapter, Repository, Observer, State, Command, Decorator…) solo aparecen mencionados en `solid.md` §2 como medio para OCP. Falta:

- el problema que resuelve cada patrón y **cuándo no usarlo** (el lado KISS/YAGNI);
- la regla *"si el proyecto ya resuelve este problema con un patrón, síguelo o justifica la desviación en Design Decisions"*;
- severidades para el mal uso (patrón sin variación real = WARN por `design-principles` §2/§5; reimplementar un patrón ya existente de otra forma = WARN).

### 5.3 Auditoría de "¿qué defecto dejaría pasar?" sobre los 16 estándares — **P1 (F88)**

Las auditorías previas validaron corrección técnica y estructura. Ninguna recorrió cada estándar preguntando qué defectos de comportamiento en su dominio **no** tienen regla ni severidad. Ejemplos de preguntas por estándar (no exhaustivo): `error-handling` — ¿qué ve el usuario durante y después de un fallo parcial?; `performance` — ¿trabajo ejecutado para resultados que nadie consume?; `concurrency` — ¿respuestas que llegan fuera de orden en un solo proceso?; `testing` — ¿tests de secuencia y de interacción entre unidades?; `security` — ¿autorización re-evaluada al cambiar de contexto/tenant?

### 5.4 Checklist de revisión congelado por dominio — **P2 (F89)**

`review-checklist.md` → UI-Specific y API-Specific son listas cortas centradas en forma (labels, contraste, método HTTP, ruta). No contienen ningún ítem de comportamiento. Al reescribirlo como índice de referencias (F82), cada sección debe incluir las preguntas de comportamiento de su dominio.

### 5.5 El Brainstormer pregunta por entradas, no por transiciones — **P2 (F90)**

`devflow-brainstorm/questions-template.md` → Edge Cases: *"Invalid, empty, or unexpected input behavior?"*. `devflow-feature/questions-template.md` no tiene categoría de edge cases. Falta la dimensión temporal genérica: *¿qué ocurre si la entrada/contexto cambia mientras hay trabajo en curso?, ¿si la acción se repite?, ¿si el usuario abandona a mitad?, ¿qué debe reiniciarse y qué conservarse?*

### 5.6 Estados de UI incompletos en la spec — **P2 (F91)**

`spec-template.md` → UI Mockups exige *default, loading, error, empty*. No contempla estados de **transición** (cambio de contexto/selección, recarga, contenido parcialmente disponible, vista inactiva/oculta). Debe generalizarse a una **Matriz de Estados e Interacciones** (estados × eventos → resultado esperado) aplicable a cualquier componente con estado, no solo a UI.

---

## 6. Calibración: el framework no sabe qué se le escapa

### 6.1 No hay retroalimentación desde la revisión externa — **P0 (F92)**

`learnings.md` recibe escrituras del Finalizer, Feature, Bug-Fix, Refactor, Templates y el remediation loop de seguridad. Ninguna ruta incorpora **lo que se detectó después** de que DevFlow aprobara: comentarios del revisor de PR, bugs de QA, incidencias. Sin esa entrada, el knowledge base solo aprende de lo que el propio framework ya sabía ver.

Propuesta: un procedimiento de **análisis de escapes** (idealmente un subcomando de `devflow-ctl` + un agente/paso) que, por cada corrección externa, registre: clase de defecto (§1.1), capa que debió detectarla (Brainstorm / Spec / Plan-tests / Implementer / Verifier / Reviewer-dimensión / Estándar ausente) y acción correctiva (nueva regla, nuevo ítem, nuevo escenario). Las entradas alimentan `learnings.md` y un registro agregable.

### 6.2 Las métricas no miden escapes — **P1 (F93)**

`metrics-template.md` → Quality registra BLOCK/WARN/INFO **encontrados** y tests creados. No existe *escape rate* (defectos encontrados después de APPROVED / total), ni su distribución por capa responsable. Es la única métrica que dice si una wave de verificación mejoró algo.

### 6.3 El eval harness no tiene tareas de corrección de comportamiento — **P1 (F94)**

`eval/tasks/` contiene 2 tareas (`001-cli-json-flag`, `002-rest-health-endpoint`), ambas de *happy path*. Para medir estas waves hacen falta tareas cuyo `checks.sh` falle ante defectos de clase transición / efecto secundario / contrato / fallo parcial, en al menos dos tipos de proyecto (backend y uno con UI), y que se ejecuten antes y después de cada wave. Los casos observados en uso real sirven aquí como **validación**, no como especificación.

### 6.4 El Reviewer no declara su cobertura — **P2 (F95)**

El documento de revisión (`review-checklist.md` → template) lista hallazgos y veredicto, pero no qué dimensiones corrieron, qué estándares se cargaron completos, qué archivos de impacto se leyeron ni qué escenarios se recorrieron. Un APPROVED sin declaración de cobertura es indistinguible de uno superficial. (Precedente en el propio framework: los scans deterministas ya anotan *"skipped scan"* como hueco visible.)

### 6.5 El Critical Friend hereda la misma restricción de citación — **P2 (F96)**

`critical-friend.md` Check 2 (Assumptions) y Check 3 (Alternatives) no exigen cita, pero el formato de salida y `rules.md` regla 6 sí. Debe alinearse con F66: un riesgo funcional con escenario concreto es un hallazgo válido sin sección de estándar.

---

## 7. Priorización

| Prioridad | Hallazgos | Criterio |
|---|---|---|
| **P0** (8) | F65, F66, F67, F72, F73, F77, F78, F92 | Una clase entera de defecto no tiene capa responsable, o la política vigente impide reportarla |
| **P1** (15) | F68, F69, F70, F74, F79, F80, F81, F82, F84, F85, F86, F87, F88, F93, F94 | Degradan la detección de forma sistemática |
| **P2** (9) | F71, F75, F76, F83, F89, F90, F91, F95, F96 | Pulido y robustez de la cadena |

---

## 8. Propuesta de olas

| Wave | Tema | Hallazgos | Racional del orden |
|---|---|---|---|
| **18** | Revisión: dimensiones, evidencia y severidad | F65, F66, F67, F68, F69, F70, F71, F72, F78, F82, F83, F95, F96 + F94 (línea base) | Mayor retorno inmediato; no depende de estándares nuevos |
| **19** | Aplicación de estándares y escenarios aguas arriba | F73, F74, F75, F77, F79, F80, F81, F90, F91 | Mueve la detección a diseño e implementación |
| **20** | Cobertura: dominios y patrones | F84, F85, F86, F87, F88, F89 | Requiere el formato de estándar de Wave 19 (F79) |
| **21** | Calibración y verificación en ejecución | F76, F92, F93, F94 | La línea base de F94 se toma al inicio de Wave 18 (plan, PR1) |

Plan detallado, PRs, dependencias y criterios de aceptación: **`docs/implementation-plan-waves-18-21.md`**.

---

## Apéndice §A — Auditoría de huecos de comportamiento por estándar (Wave 20, F88)

> Recorre los 20 estándares (los 16 originales + los 4 de Wave 20) con una sola pregunta: **¿qué defecto de comportamiento en este dominio no tiene regla ni severidad?** Un hallazgo real se cierra con una edición mínima al estándar (sin renumerar secciones) o con un enlace al estándar que ya es dueño del hueco. La ausencia de hallazgo también se registra — "sin huecos" no es lo mismo que "no se revisó".

| Estándar | Hueco encontrado | Acción |
|---|---|---|
| `design-principles.md` | Sin huecos de comportamiento — cubre calidad de diseño (DRY/YAGNI/SoC/KISS), no corrección de ejecución | Ninguna |
| `solid.md` | Sin huecos — LSP (§3) ya cubre sustitución que rompe comportamiento en tiempo de ejecución | Ninguna |
| `clean-architecture.md` | Sin huecos — es un estándar estructural; los defectos de comportamiento que produce (una entidad de ORM filtrada) ya tienen dueño en `integration-consumption.md §7` | Ninguna (cross-link ya registrado en `standards-dry-policy.md`, PR19) |
| `project-design.md` | Sin huecos de comportamiento — selección de patrón arquitectónico | Ninguna |
| `security.md` | Una autorización cacheada (sesión, token, flag en memoria) que sigue vigente después de que el permiso subyacente cambió no estaba cubierta explícitamente | **Editado** (PR22): DO/DON'T añadidos a §2, disparador WARN añadido a §11 |
| `error-handling.md` | Un fallo durante la propia limpieza/rollback (el `finally`/`catch` que libera recursos falla a su vez) no estaba cubierto — la excepción original o la de limpieza puede perderse en silencio | **Editado** (PR22): DO/DON'T añadidos a §6, disparador WARN añadido a §9 |
| `testing.md` | El razonamiento de mutación y las secuencias de comportamiento ya se resolvieron en Wave 18/19 (`correctness-guide.md`, `behavior-scenarios.md`) | Ninguna — ya enlazado |
| `performance.md` | El consumo condicionado a que algo esté realmente activo ya es dueño de `state-lifecycle.md §7`; ningún hueco adicional | Ninguna (cross-link ya registrado, PR18) |
| `rest-api.md` | La idempotencia del lado servidor ya está en §9; el lado cliente (reintentos) es de `integration-consumption.md §3` | Ninguna (cross-link ya registrado, PR19) |
| `testing.md` (concurrencia) | Cubierto por `concurrency.md §2` y el requisito de test de concurrencia real | Ninguna |
| `concurrency.md` | Sin huecos nuevos — las secciones nuevas de Wave 20 (`state-lifecycle.md §5`, `integration-consumption.md §2`, `data-persistence.md §3`) ya referencian esta sección como dueña de la disciplina general | Ninguna |
| `dependencies.md` | Sin huecos de comportamiento — es de cadena de suministro | Ninguna |
| `event-driven-architecture.md` | Sin huecos — orden, entrega, DLQ ya cubiertos | Ninguna |
| `ui-design.md` | Una transición de estado (Loading/Error/Success) aplicada a la instancia equivocada de un componente después de que su selección cambió no estaba mencionada en la propia sección de estados | **Editado** (PR22): DON'T añadido a §6, con referencia a `state-lifecycle.md §6` como dueño del mecanismo |
| `accessibility.md` | Sin huecos — contenido dinámico y anuncios ya cubiertos en §7 | Ninguna |
| `logging.md` | Sin huecos de comportamiento — el valor registrado podría no coincidir con el estado realmente persistido, pero es un caso marginal sin evidencia de que ocurra en la práctica | Ninguna (queda como INFO implícito, no se fuerza una regla sin caso real) |
| `git-conventions.md` | Sin huecos — no gobierna comportamiento en ejecución | Ninguna |
| `state-lifecycle.md` | Nuevo en esta wave (PR18) — sin historial de revisión todavía | Ninguna — revisar en la próxima auditoría |
| `integration-consumption.md` | Nuevo en esta wave (PR19) — sin historial de revisión todavía | Ninguna — revisar en la próxima auditoría |
| `data-persistence.md` | Nuevo en esta wave (PR20) — sin historial de revisión todavía | Ninguna — revisar en la próxima auditoría |
| `design-patterns.md` | Nuevo en esta wave (PR21) — sin historial de revisión todavía | Ninguna — revisar en la próxima auditoría |

**Resumen:** 3 ediciones reales (`security.md`, `error-handling.md`, `ui-design.md`), ninguna con renumeración de secciones; el resto de los huecos ya tenía dueño (los 4 estándares nuevos de esta wave) o no aplicaba. `review-checklist.md` gana un ítem de comportamiento en API-Specific Checks (`concurrency.md §2`) y en UI-Specific Checks (`ui-design.md §6` + `state-lifecycle.md §6`), citando la fuente en vez de repetirla.
