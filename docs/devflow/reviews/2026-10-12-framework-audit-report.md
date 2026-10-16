# Auditoría Integral del Framework DevFlow — Reporte Completo

> **Fecha:** 2026-10-12
> **Versión auditada:** 4.16.1 (`package.json` + `package-lock.json` + `CHANGELOG.md ## [4.16.1]` sincronizados)
> **Alcance:** todos los flujos (`/devflow` 8 fases + 11 standalone), todos los comandos (`devflow-ctl`, `devflow-eval`, scripts), los 21 estándares de `shared/standards/`, patrones de diseño, seguridad, prompts, editor-profiles, tests e instaladores.
> **Metodología:** lectura completa de los 19 `SKILL.md` (~3751L), `shared/*.md` + `standards/` (~10600L), `scripts/`, `install/uninstall.sh|ps1`, `editor-profiles/`, `permissions/`, `tests/*.bats`, `eval/`; ejecución de `scripts/validate-framework.sh` (exit 0, verde) y verificación puntual por grep de los hallazgos críticos. Ningún archivo fue modificado durante la auditoría.
> **Estado del validador:** el gate determinista pasa, lo que significa que los problemas abajo son de **lógica, semántica, seguridad y handoffs** — clases que el validador actual no cubre (ver §8).

---

## Índice

1. [Resumen ejecutivo](#1-resumen-ejecutivo)
2. [Flujo principal `/devflow` — orquestador + 7 fases con skill](#2-flujo-principal-devflow--orquestador--7-fases-con-skill)
3. [Agentes standalone (`feature`, `bug-fix`, `refactor`, `perf`, `migrate`, `contract`, `docs`, `templates`, `tutorial`, `reverse`, `test`)](#3-agentes-standalone)
4. [Estándares (`shared/standards/`) — corrección técnica](#4-estándares-sharedstandards--corrección-técnica)
5. [Patrones de diseño](#5-patrones-de-diseño)
6. [Seguridad (framework + estándares + permisos)](#6-seguridad-framework--estándares--permisos)
7. [Comandos, scripts, prompts, editor-profiles, tests, eval](#7-comandos-scripts-prompts-editor-profiles-tests-eval)
8. [Puntos ciegos del validador y causa raíz transversal](#8-puntos-ciegos-del-validador-y-causa-raíz-transversal)
9. [Plan de corrección priorizado](#9-plan-de-corrección-priororizado)
10. [Anexo — inventario verificado](#10-anexo--inventario-verificado)

---

## 1. Resumen ejecutivo

**Veredicto global:** framework maduro y muy por encima de la media en documentación, determinismo (`devflow-ctl` como enforcement real, no decorativo) y disciplina TDD/scope-locking. El trío `feature` / `bug-fix` / `refactor` es sólido; `security.md` es el mejor estándar individual. **Pero hay defectos reales que deben corregirse**, concentrados en:

| Severidad | Cantidad | Dónde |
|---|---|---|
| 🔴 Crítica (bypass aprobación, RCE, pérdida datos, bloqueo CI) | 9 | Permisos allowlist por prefijo (§6.2), `curl\|bash` sin verificación (§6.1), supply-chain en allow (§6.3), contador `implement_debug` triple-escritor (H4), `sca` BLOCK→WARN degradado (H29/H45), borrado sesión sin gate traceability (H42), `init` sin scope + `scope check` posterior (T5), Brainstorm sin mode-awareness bloquea CI (H9), Stack Mode Gate sin bypass CI (H18) |
| 🟠 Alta (doble ejecución, gates divergentes, handoffs rotos) | 18 | Doble invoke Architect→Planner (H13) e Implementer→Reviewer (H24), ruteo Step 3 vs 4 (H2), mensaje salta Fase 2 (H1+H8), branch/checkpoint ownership duplicado (H25), Implementer sin modo standalone (H26), traceability MANDATORY no verificada en gate (H19), review APPROVED que no garantiza finalize (H30), loop Reviewer→Planner sin contador (H31), sobreescritura reviews/debugs (H32), Debugger sin scope-check ni traceability (H27/H38), Finalizer interactivo sin bypass (H41), `git config --global` sin consentimiento (I-1.5), `rm -rf` guardias incompletas (I-1.6/1.7), colisión `opencode`↔`generic` mismo `user_dir` (I-6) |
| 🟡 Media (contradicciones estándares, obsolescencia 2026, robustez scripts) | ~35 | OCP vs YAGNI (C1), borde vs dominio (C2), layer-first vs feature-based (C3), 44×44 vs 24×24 (C4), pin vs rango (C5), lossy vs lossless (C6), idempotencia 5×BLOCK (C7), OWASP 2021 sin API Top 10 2023 ni LLM Top 10 2025, MFA sin passkeys, TLS sin versión mínima, `sed` sin escapar, OS `linux-gnu*`, sin modo no-interactivo, YAML awk frágil, validador no portable a macOS, ARCHITECTURE.md ~15 links rotos, tests sin VS Code / sin `jq` guard / listas hardcodeadas |

**Lo que está bien y no debe tocarse:** `devflow-ctl` (2828L, códigos 0/1/2, locks, gates, artifact sections) + `phase-state.md` frontmatter; paridad skill↔prompt 19↔19; version headers + append-only en estándares; review pipeline ≤5 estándares con checklist 1-sección→1-subagente; TDD Red→Green con definición de Red válido; scope Three Zones; `memory-conventions.md` + `framework-memory.md` con precedencia y privacy guard; eval golden tasks outcome-only + baselines.

---

## 2. Flujo principal `/devflow` — orquestador + 7 fases con skill

Referencias: `.agents/skills/devflow/SKILL.md` (436L), `devflow-brainstorm/SKILL.md` (64L), `devflow-architect/SKILL.md` (193L), `devflow-plan/SKILL.md` (172L), `devflow-implement/SKILL.md` (201L), `devflow-review/SKILL.md` (259L), `devflow-debug/SKILL.md` (126L), `devflow-finalize/SKILL.md` (151L). Fase 2 (Validation Gate) sin skill propio — la corre el orquestador.

### 2.1 Orquestador (`devflow/SKILL.md`)

| ID | Severidad | Hallazgo | Evidencia | Corrección propuesta |
|---|---|---|---|---|
| H1 | 🟠 Alta | Mensaje de progreso salta la Fase 2: tras Fase 1 dice "Next: Phase 3 — Architect", omitiendo el Validation Gate obligatorio | `devflow/SKILL.md:132` vs Execution Flow L56-58 y Step 2 L135 (verificado por grep) | Cambiar a "Next: Phase 2 — Validation Gate (automatic)" |
| H2 | 🟠 Alta | Ruteo erróneo en Confirmation Gate: "route back to Step 3 (Planner)" cuando Step 3 es Architect y Planner es Step 4 | `devflow/SKILL.md:213`; Steps 7 (L277-278) sí usan Step 3=Architect / Step 4=Planner correctamente (verificado) | Cambiar L213 a "Step 4 (Planner)" |
| H3 | 🟡 Media | Tabla rollback: "User cancels at Validation Gate → Undo spec + plan + validation artifacts" — en ese punto no existen spec (F3) ni plan (F4) | `devflow/SKILL.md:367` | "Undo validation artifacts + context checkpoint" |
| H4 | 🔴 Crítica | **Triple escritor del contador `implement_debug`**: orquestador L289 + Implementer L135 + Debugger L109 incrementan el mismo contador con límite 3 (`devflow/SKILL.md:335`). Un retry lógico consume 2 incrementos → escalación prematura con triage | `devflow/SKILL.md:289`, `devflow-implement/SKILL.md:135` (reportado), `devflow-debug/SKILL.md:109` (reportado) | Propiedad única: solo el Debugger incrementa; orquestador e Implementer solo leen (`iterate check`). Añadir test `devflow-ctl.bats`: doble `iterate` desde dos agentes cuenta 2, y documentar ownership en `rules.md` |
| H5 | 🟠 Alta | Duplicación de validación pre-finalización no idéntica: orquestador Step 9 gatea traceability 100% pero no `backlog INCOMPLETE`; Finalizer gatea backlog pero no traceability. En `/devflow-finalize` standalone el gate de traceability se bypasea | `devflow/SKILL.md:299-312` vs `devflow-finalize/SKILL.md:39-44` | Mover ambos gates al Finalizer Step 2 como STOP (traceability 100% + backlog), orquestador solo re-verifica; añadir `traceability check` al Completion Protocol del Finalizer |
| H6 | 🟡 Media | Doble archivado de validación sin idempotencia: orquestador archiva a `docs/devflow/validations/YYYY-MM-DD-{slug}-validation.md` (L154) y Finalizer re-archiva "if not already done" (L127-130). Cruce de medianoche = 2 archivos divergentes; mismo día = overwrite sin hash | Citado | Regla: nombre canónico fijado por orquestador en `phase-state.md`; Finalizer solo copia si el hash difiere, nunca sobrescribe |
| H7 | 🟡 Media | Pausa en Autonomous sin resume: al agotar Debugger se escribe `send-to-user.md` y "pause the cycle", pero Step 0 solo reanuda fases incompletas, no estado `paused` | `devflow/SKILL.md:295` vs L109 | Añadir estado `paused` a `phase-state.md` + Step 0: `if status=paused → resume from checkpoint` |

### 2.2 Brainstormer (Fase 1)

| ID | Sev. | Hallazgo | Evidencia | Fix |
|---|---|---|---|---|
| H8 | 🟠 Alta | Handoff con fase equivocada: "invoke @devflow-architect to proceed to Phase 2" — Fase 2 es Validation Gate, Architect es Fase 3. Step 3 repite el salto. Viola "NEVER skip phases" | `devflow-brainstorm/SKILL.md:57-60` (verificado: L60 dice Phase 2), Step 3 L42 | "Proceed to Phase 2 — Validation Gate (run by orchestrator); Architect is Phase 3" |
| H9 | 🔴 Crítica | Sin mode-awareness: exige STOP + aprobación explícita sin vía auto-approve. En CI/Autonomous el ciclo se cuelga en Fase 1 aunque el orquestador promete auto-aprobación posterior | `devflow-brainstorm/SKILL.md:39,43-46` (verificado STOP), sin mención CI/Autonomous a diferencia de Implementer/Debugger/Reviewer/Finalizer | Añadir: `if CI=true or Autonomous → inferir, registrar supuestos en context.md, continuar sin STOP` |
| H10 | 🟠 Alta | Duplica gestión de sesión sin `devflow-ctl`: lista/pregunta continue/new manual y escribe `context.md`/`phase-state.md` sin frontmatter, lock, checkpoint `pre-phase-1` ni métricas que el orquestador verifica (Step 1 L126-127) | `devflow-brainstorm/SKILL.md:25-28,50-53` | Invocar `devflow-ctl status/lock/init/checkpoint` o delegar sesión 100% al orquestador en ciclo |
| H11 | 🟡 Media | `Load Memory` imposible: `memory query --stack {stack}` (L33) pero stack queda como `[To be detected by Architect]` (L52). Huevo-gallina sin fallback | Citado | Fallback: `--stack unknown` u omitir flag; documentarlo |
| H12 | 🟡 Media | Headings del contrato (`## Goal`, `## Definition of Done`, `## Constraints`) delegados a `questions-template.md` sin transcripción; si el template usa otros nombres, la validación del orquestador falla sistemáticamente | Orquestador L126/L130 vs Brainstorm L52 | Transcribir los 3 headings exactos en el SKILL, template solo formato |

### 2.3 Architect (Fase 3)

| ID | Sev. | Hallazgo | Fix |
|---|---|---|---|
| H13 | 🟠 Alta | Auto-invoke incondicional a Planner (`architect:175`) + orquestador Step 3 también invoca Planner → **doble ejecución del Planner en `/devflow`**. Planner sí distingue lifecycle vs standalone; Architect no | Añadir guarda: `if invoked by orchestrator → return spec path, STOP (orchestrator invokes Planner); else (standalone) → auto-invoke devflow-plan` |
| H14 | 🟠 Alta | Completion Protocol contradice Cancel: "Cancel → Discard (do NOT call create_file)" (L160) vs "If you cannot confirm create_file was called → call it NOW" (L189). Tras Cancel obliga a crear lo descartado | Eximir Cancel del protocolo: `if Cancel → skip file-confirmation branch` |
| H15 | 🟡 Media | `Feature Type` nunca asignado a dueño: Architect lo lee de `context.md → Stack Profile` (L77) pero nadie lo fija; Planner también lo lee (L101). Detección UI/mockup indefinida | Architect Step 3 debe fijar `Feature Type` explícitamente (inferido + confirmado) y persistirlo |
| H16 | 🟡 Media | Exploración reducida con AGENTS.md asume frescura sin validarla (L111-116). AGENTS.md obsoleto propaga Stack Profile erróneo | Añadir freshness check: `git log -1 --format=%ci AGENTS.md` + campos `unknown` → forzar exploración completa |
| H17 | 🟡 Media | Referencia a sub-pasos de `exploration-guide.md` no autocontenida (L104-116); el orquestador no puede validar cobertura | Incluir checklist de ejes en el SKILL o citar secciones exactas del guide |

### 2.4 Planner (Fase 4)

| ID | Sev. | Hallazgo | Fix |
|---|---|---|---|
| H18 | 🔴 Crítica | Stack Mode Gate pregunta `stack_mode` sin rama auto (L42-50); en CI/Autonomous se detiene. Inconsistente con Confirmation Gate del orquestador que sí auto-aprueba | Añadir: `if CI/Autonomous → default stack_mode=no (o inferido de memoria), loguear` |
| H19 | 🟠 Alta | `traceability.md` MANDATORY (Step 8a L109-117) pero orquestador Step 4 solo verifica plan + mockups + `phase-state.md` (L195-198). Planner defectuoso pasa el gate y falla 4 fases después en finalize | Añadir `traceability check` al gate del orquestador Step 4 |
| H20 | 🟡 Media | Marca `[x] Phase 4` al persistir (L147-151), antes del Confirmation Gate. Si el usuario pide cambios, re-trabajo sin transición de estado | Marcar Phase 4 completa solo tras Confirmation Gate; antes: `Phase 4 (pending approval)` |
| H21 | 🟡 Media | `rigor` vía `devflow-ctl config set` (L65-74) sin default fuera de ciclo; Implementer/Reviewer standalone ramifican por rigor indefinido | Default `rigor=standard` si no configurado; `config get` con fallback |
| H22 | 🟡 Media | Step 3 exige Validation Report sin fallback standalone (L55) | `if no validation-report (standalone) → proceed with assumption-logging` |

### 2.5 Implementer (Fase 5)

| ID | Sev. | Hallazgo | Evidencia/Fix |
|---|---|---|---|
| H23 | 🟡 Media | Frontmatter "Executes no tests" contradice auto-ejecución Standard (L27). Los routers leen la description | Verificado `devflow-implement/SKILL.md:3`. Cambiar a "Mode-aware: auto-executes tests/git in Standard/CI; informs exact command in Pair" |
| H24 | 🟠 Alta | Auto-invoke incondicional a Reviewer (L38, Step 6 L195-198) + orquestador Step 7 también invoca → doble review en `/devflow`. Falta la guarda lifecycle/standalone que Planner sí tiene | Misma guarda que H13 |
| H25 | 🟠 Alta | Doble creación branch/checkpoint: orquestador Step 6 crea branch + `pre-phase-5` (L249-254); Implementer asume auto-branch/commit. Segundo `checkout -b` falla | Ownership: orquestador crea branch; implementer solo commitea. Documentar en `rules.md` |
| H26 | 🟠 Alta | Sin modo standalone: `gate check confirmation` con STOP garantizado (L47, verificado) hace `/devflow-implement` standalone inutilizable (nunca hubo gate). Reviewer sí resolvió con Cycle/Standalone | Añadir Standalone Mode: `if no confirmation gate state → treat plan file as approved scope, log assumption` |
| H27 | 🟠 Alta | Debugger sin `scope check` rompe la cadena que Implementer cumple y Reviewer audita como BLOCK | Añadir `scope check` + `scope justify` al Debugger Step 4 antes de cada edit |
| H28 | 🟡 Media | Skip metrics divergentes: Implementer cuenta tasks, Reviewer cuenta files (L174-178 vs Reviewer L79-84). Defensa impredecible | Unificar métrica (files + tasks) en tabla única en `rules.md` |

### 2.6 Reviewer (Fase 6)

| ID | Sev. | Hallazgo | Evidencia/Fix |
|---|---|---|---|
| H29 | 🔴 Crítica | **Contradicción `scan sca`**: Reviewer "every scanner finding → BLOCK" (L73, verificado) vs Finalizer "Critical/High → WARN" (L44). CVE entre review y finalize se resume como WARN y el ciclo completa con vuln crítica conocida | Decidir política única: `sca` High/Critical = BLOCK en ambas fases. Fix en `devflow-finalize/SKILL.md:44` |
| H30 | 🟠 Alta | Traceability WARN (fila no cubierta → WARN salvo DoD/HIGH-risk) vs gate finalize 100%. APPROVED en F6 no implica alcanzabilidad de F8 | Elevar a BLOCK toda fila DoD-linked + exigir `traceability check` verde antes de APPROVED, o relajar gate finalize a "100% DoD-linked" |
| H31 | 🟠 Alta | Ruta Reviewer→Planner sin contador: `plan_revision` vs `implement_review` sin mapeo para el caso cycle. Loop potencialmente infinito | Mapeo explícito: cycle Planner-loop consume `plan_revision`; documentar en orquestador L329-336 |
| H32 | 🟠 Alta | Sobreescritura: re-reviews (hasta 3 iteraciones) y debug logs usan ruta dated fija → se pierde historial; métrica BLOCKs cuenta solo el último | Sufijo iteración: `-r1`, `-r2` / `-dbg1`; Finalizer agrega sobre todos |
| H33 | 🟡 Media | Nota de deriva dejada en norma: "(limit 3, not the "2" this used to say in prose…)" (L246, verificado). Indica desync prosa-vs-CLI no limpiado | Limpiar nota; grep global "limit 2" y unificar a `iterate_default_max` como fuente |
| H34 | 🟡 Media | Orden spec/plan vs blind pass contradictorio en Step 1 (L53-54): "lee" y "no leas aún" coexisten | Reescribir Step 1 como: blind pass primero (ciego), luego spec/plan, con orden explícito |
| H35 | 🟡 Media | "Wave 12" colgada (L75, verificado): sin definición en el ciclo | Sustituir por "when the plan declares an Impact Zone (see plan-template §…)" |

### 2.7 Debugger (Fase 7)

| ID | Sev. | Hallazgo | Fix |
|---|---|---|---|
| H36 | 🟡 Media | Critical Friend contempla escalación arquitectónica (L56-62) sin dueño: ¿aborta Debugger u orquestador? Orquestador solo escala tras 3 intentos (L295) | Rama explícita: `if root cause is architectural → STOP, report to orchestrator with evidence, orchestrator routes to Architect (consume plan_revision)` |
| H37 | 🟠 Alta | Agravante de H4: consume intento incluso con fallo reportado por usuario en Pair sin verificación propia (L109) | Solo incrementar tras intento de fix propio verificado |
| H38 | 🟠 Alta | No actualiza `traceability.md`: fix con archivo nuevo deja matriz stale → `traceability check` falla por omisión del Debugger | Añadir Step: actualizar traceability con archivos/escenarios del fix |
| H39 | 🟡 Media | Marca Fase 7 completa (L123) pero orquestador rutea a Implementer "for re-verification" (L294). Estado stale si se re-rompe | Transición atómica Debugger→Implementer→Debugger; desmarcar F7 al re-entrar a F5 |
| H40 | 🟡 Media | Slug indefinido en standalone: `iterate --slug` exige slug (L109) pero frontmatter no lo incluye (L4) | Frontmatter + Step 0: resolver slug (argumento o `devflow-ctl status`) o modo sin contador |

### 2.8 Finalizer (Fase 8)

| ID | Sev. | Hallazgo | Evidencia/Fix |
|---|---|---|---|
| H41 | 🔴 Crítica | 3 pasos interactivos sin bypass auto (confirman artefactos L133 verificado; escape analysis L63; DoD L40). En Autonomous la **última fase** se detiene sin usuario | Rama `if Autonomous/CI → auto-confirm with checklist log to send-to-user.md` en los 3 puntos |
| H42 | 🔴 Crítica | Sin gate propio de traceability antes del borrado destructivo (Step 3 L60 / Step 4 L86 solo métricas/reporte). Standalone con 60% coverage genera summary "completo" y **borra la evidencia** (Step 5.4) | STOP si `traceability check` ≠ 100% antes de Step 5.4; mismo para tests/BLOCKs ya existentes |
| H43 | 🟡 Media | Lock-release vs borrado sin rama de error: `lock release` explícito-antes (L133 verificado) vs orquestador "released implicitly" (L316) | Unificar modelo (explícito) + `if lock release fails → abort deletion, report` |
| H44 | 🟡 Media | 5 superficies de escritura (métricas, learnings, framework memory, standards-profile, project-template) sin verificación post-escritura; orquestador solo verifica summary + limpieza | Checklist post-escritura con hash/conteo antes de declarar completo |
| H45 | 🔴 Crítica | `scan sca` degradado (ver H29): Critical/High → WARN, no bloquea borrado | Mismo fix que H29 |

### 2.9 Handoffs transversales del ciclo

- **T1 (Brainstorm→Gate→Architect):** H1+H8 hacen la Fase 2 invisible en mensajes de ambos lados; operador manual la salta siempre. Fix H1+H8 corrige.
- **T2 (Architect→Planner→Confirmation):** H13+H20+H2 en la misma costura. Fixes respectivos.
- **T8 (herramientas):** `create_file`/`read_file` vs `replace_file_content`/`multi_replace_file_content` (Debugger L93) sin alias. Fijar mapeo canónico en `rules.md` y citarlo en cada SKILL.

---

## 3. Agentes standalone

Lectura completa de los 11 `SKILL.md`. `feature`/`bug-fix`/`refactor` son coherentes (defectos puntuales); `perf`/`migrate`/`contract` comparten esqueleto degradado; `docs`/`templates`/`tutorial`/`reverse` con defectos de fidelidad/cierre; `test` funcional pero fuera de protocolo.

### 3.1 `devflow-feature` (273L) — referencia de facto ✅ con 3 matices

1. **Critical Friend vs CI deadlock** (🟡): S1 tiene excepción CI (inferir, `feature:59`) pero S1.5 exige resolver BLOCK sin excepción CI (`feature:76`). Fix: `in CI → log BLOCK as assumption-risk, continue; surface in report`.
2. Commit por tarea ruidoso sin justificación vs bug-fix (1 commit). Documentar criterio o unificar.
3. S7 duplica verificación de S5/S6 (reconocido en `feature:202`). Aceptable pero genera doble reporte; fusionar en un único Verification Summary.

Fortalezas a preservar: Complexity Gate cuantificado (`>5 ficheros, capa arquitectónica, >2 componentes → /devflow`), scope Three Zones con `justify` vs `backlog`, TDD Red/Green con `(discovered)` vía `behavior-scenarios.md`, entry conditions y cierre S9→S10→S11.

### 3.2 `devflow-bug-fix` (266L) — sólido, 3 defectos

1. **Contradicción lectura S3** (🟡): "Read **only** causal chain" (`bug-fix:98`) vs "chain is discovered by reading, cannot limit reading" (`bug-fix:103`). Eliminar la primera frase.
2. **Full suite fantasma** (🟠): S7 afirma suite corrida en S6 (`bug-fix:186`) pero S6 solo ordena single-file repro (`bug-fix:166`). Añadir full suite a S6 o corregir S7.
3. **Asimetría Reviewer** (🟡): ante BLOCK fuera de scope, feature añade INFO note (`feature:226`); bug-fix no instruye (`bug-fix:221`) → hallazgo perdido. Copiar el patrón de feature.

### 3.3 `devflow-refactor` (273L) — scope-lock ejemplar, sin escalado

1. **Sin Complexity Gate** (🟠): único agente que muta código sin tabla de escalado. ¿Refactor 20 ficheros / nueva abstracción? Añadir gate espejo de feature con umbrales propios (`>8 ficheros, cambio API pública, nueva abstracción → /devflow`).
2. Numeración rota S6 ítem "0." (`refactor:150`) → renumerar.
3. TEST POLICY ambigua (`refactor:30`) → "tests configured AND existing tests present".
4. S7 informa verificación antes del behavior check (`refactor:166-174`) → mover mensaje tras PASS.
5. Jerga Core/Impact Zone sin definir (`refactor:99`) → citar `rules.md → Three Zones` en cada uso como hacen feature/bug-fix.

### 3.4 `devflow-perf` (155L) — read-only correcto, protocolo degradado ⚠️

1. **Sin `STOP/wait` S4→S5** (🟠): asume output del usuario sin parada explícita → reporte sin evidencia. Añadir STOP.
2. **`init` sin `--scope`** (🔴, T5): "Scope-locked" (`perf:24`) inaplicable con `init --mode perf --slug` sin scope (`perf:42`). Añadir `--scope {target}`.
3. Métricas off-by-one: "empty until Step 8" (`perf:44`) pero finalize es Step 9. Corregir + añadir `metrics aggregate`.
4. Sin write-back a learnings (lee Performance en S2, nunca escribe) → añadir S-write-back + escape analysis como feature/bug-fix/refactor.
5. S4 ambiguo crea-vs-muestra benchmark (`perf:96-99`) → aclarar: solo snippet mostrado, nunca archivo (coherente con NEVER generate files).
6. Escalado vago (`perf:30-34`) → script de recomendación como feature/bug-fix.

### 3.5 `devflow-migrate` (153L) — garantías correctas, protocolo incompleto ⚠️

1. **Scope roto en la práctica** (🔴, T5): `init` sin scope (`migrate:31`) + `scope check` en S5 (`migrate:101`) → check falla siempre. Añadir `--scope {migration-dir}`.
2. **Sin Mode Selection** (🟠): único que escribe archivos sin modos/pair_mode/excepción CI; gate de 3 opciones vs 4 de feature/bug-fix/refactor. Añadir sección modos + 4ª opción.
3. **Sin rama BLOCK del Reviewer** (🟠): S7 invoca sin definir qué hacer (`migrate:121-128`). Copiar rama de feature.
4. Métricas off-by-one ("until Step 7", finalize Step 8) + sin aggregate + sin write-back.
5. Sin escalado pese a operaciones destructivas → gate (`DROP, cambio tipo columna en tabla grande, multi-DB → /devflow`).
6. S3 pregunta breaking changes (`migrate:75`) sin ordenar grep de queries afectadas → añadir paso.

### 3.6 `devflow-contract` (142L) — mismos defectos que migrate ⚠️

1-3. Idénticos a migrate (scope T5, gate 3 opciones, sin rama BLOCK). Mismos fixes.
4. **Sobreescritura indefinida**: "generate … if none exists" (`contract:84`) sin caso existe → definir merge/skip/overwrite con aprobación.
5. "Analyzes coverage" prometido sin procedimiento → definir o retirar claim; sin escalado para mismatch masivo → gate (`>50% endpoints mismatch o rediseño contrato → /devflow`).

### 3.7 `devflow-docs` (141L) — buen merge-gate, 5 gaps

1. Sin Critical Friend (único de contenido sin S1.5) → añadir revisión adversarial del spec fuente.
2. Sin Load Memory (no `memory query`; cita learnings solo como fuente `docs:102`) → añadir query + write-back.
3. S3 atajo no canónico (`docs:72` detecta stack de configs, bypassa Quick Stack Detection, no escribe `context.md`) → usar `stack-detection.md` y persistir.
4. Fuentes muertas: S1 lista metrics/perf/migrations/contracts (`docs:39-42`), S4 los ignora → consumir o retirar.
5. Sin `metrics aggregate`, sin rama BLOCK → mismos fixes.

### 3.8 `devflow-templates` (261L) — potente, cierre más inconsistente ⚠️

1. **Reviewer desigual** (🟠): Project Template sin manejo BLOCK (`templates:121-125`); Standards Profile comprime 3 pasos (`templates:161-163`); **Bootstrap escribe a `learnings.md` compartida sin Reviewer** (`templates:244-246`, el caso más riesgoso sin control) → Reviewer obligatorio en los 3 procedimientos.
2. **Sin `artifacts check`** (🟡): único junto a tutorial sin validación en Completion (`templates:250-257`) → añadir.
3. Sin Critical Friend en 3 procedimientos → añadir (fosilizar errores en templates es de alto impacto).
4. Gate malformado "`{generate | update}`" (`templates:60`) → corregir sintaxis.
5. Tipos sin referencia: Desktop App / GraphQL referenciados (`templates:45,50`) pero `shared/templates/` solo tiene 6 (api-rest, cli-tool, fullstack, library-sdk, mobile-app, web-frontend) → crear los faltantes o retirar menciones.

### 3.9 `devflow-tutorial` (85L) — más débil normativamente ⚠️

1. **Omite Phase 7 Debugger** sin explicación → añadir fase demo o justificar ("demo sin fallos; Debugger se muestra en …").
2. **Conteo erróneo**: "all 10 standalone agents" (`tutorial:71`); repo tiene 10 standalone + test-helper = 11 skills → corregir a 11 (o 10 + helper).
3. Cheatsheet sin prefijo fecha (`tutorial:75`) sobrescribe cada corrida → usar `YYYY-MM-DD-{slug}-cheatsheet.md` o estrategia merge.
4. Sin Reviewer (único standalone sin auto-invoke) → añadir revisión de docs generadas.
5. Métricas erróneas ("until Step 6", finalize Step 10, `tutorial:27`) → corregir + aggregate.
6. Riesgo lock: sesión tutorial separada + agentes invocados con `lock check` (`tutorial:25`) → documentar compatibilidad o usar slug compartido.

### 3.10 `devflow-reverse` (244L) — profundo, 5 defectos fidelidad

1. **Reviewer con `Feature Type: backend` hardcodeado** (`reverse:201`) → dinámico desde Stack Profile.
2. Reintento no canónico ("once more… after 2 iterations", `reverse:206`) vs `iterate implement_review` → unificar.
3. Gate S4.5 cubre 3 artefactos (`reverse:97`) pero S11 persiste 5 → extender gate a Stack Profile + report.
4. **CVE por versión sin método** (`reverse:161`) → riesgo alucinación. Exigir `devflow-ctl scan sca` o base de datos declarada; sin herramienta, marcar como "heuristic, verify".
5. Sin aggregate, sin write-back (lee para no re-descubrir `reverse:64`, no contribuye).

### 3.11 `devflow-test` (56L) — helper mínimo fuera de protocolo

1. Stack Mode inalcanzable (`test:32` sin cargar Stack Profile) → cargar o retirar condición.
2. Deriva vocabulario: `replace_string_in_file` (`test:37`) vs `replace_file_content`; `FAIL expected` (`test:43`) vs `red-confirmed/passing` → unificar.
3. Sin fallback si el plan no tiene `🧪 Tests` → definir STOP con mensaje.
4. Sin lock check → riesgo corrupción concurrente de `test-registry.md`; añadir `lock check` de lectura.

### 3.12 Transversales standalone

| # | Patrón | Afecta |
|---|---|---|
| T1 | Reviewer sin rama BLOCK | migrate, contract, docs, templates (parcial), perf |
| T2 | Métricas off-by-one | perf, migrate, contract, tutorial |
| T3 | Sin `metrics aggregate` | perf, migrate, contract, docs, templates, tutorial, reverse |
| T4 | Lee learnings, no escribe | perf, migrate, contract, docs (parcial), reverse |
| T5 | `init` sin `--scope` + `scope check` posterior (🔴) | perf, migrate, contract |
| T6 | Gate 3 opciones sin modos/CI | migrate, contract |
| T7 | CI vs Critical Friend sin resolver | feature, bug-fix, refactor, migrate |
| T8 | Sin Critical Friend | docs, templates, tutorial |
| T10 | Reintentos divergentes | reverse vs resto |

---

## 4. Estándares (`shared/standards/`) — corrección técnica

Nivel general alto (version headers, Severidad, Scope-safe, Self-Check, política DRY con citas canónicas). Problemas: sobre-absolutismo, sesgo OOP/JVM y Node, contradicciones de severidad, gaps OWASP 2024-2026.

### 4.1 `solid.md` — correcto, dogmático en OCP/DIP

- **OCP §2**: prohibir `if/else/switch` como absoluto genera falsos positivos en `match` exhaustivo Rust/Go/TS discriminated unions (idiomático y más seguro que jerarquía). §6 lo matiza pero §8 lo eleva a WARN. Fix: WARN solo si hay ≥2 casos de variación real o el switch viola Open/Closed probado (nuevo caso rompe existentes); citar YAGNI.
- **LSP §3**: `final/sealed` ubicuo rompe OCP. Fix: sellar contrato público, abrir punto de extensión; criterio explícito.
- **ISP §4**: fragmentar `Repository<T>` en `Readable/Writable` rompe cohesión transaccional (`UnitOfWork`). Fix: admitir header interfaces para ports/mocking.
- **DIP §5**: BLOCK por "cualquier `new` de infraestructura en dominio" bloquea DDD válido (`new Money()`, `new DomainException()`, `UUID`, `Instant`). Fix: exceptuar value objects, excepciones de dominio y tipos estables stdlib.

### 4.2 `security.md` — el más sólido, anclado en OWASP 2021

Correcto: allowlist-first, no-rollear-auth, HttpOnly, vault, parametrizadas, CSP, Argon2id>bcrypt, JWT `alg:none`/`exp`, threat-model.
Gaps/correcciones:

- Auth §2: mezcla bearer-JS vs cookie-HttpOnly sin patrón BFF; sin DPoP/sender-constrained (2024-26), sin prefijo `__Host-`, sin `aud/iss` estricto, sin confusión `kid/jku/x5u`. Añadir.
- MFA §7: "TOTP sobre SMS" es 2022; **NIST 800-63B-4 exige passkeys/WebAuthn phishing-resistant preferente**. Añadir + ventana re-auth (no "remember forever").
- Passwords: falta pepper, costo/memoria, límite 72B bcrypt, HIBP k-anonimity. Añadir.
- Transporte: sin TLS 1.2+ mínimo, sin `includeSubDomains/preload`, sin atributos cookie. Fijar.
- Reposo: "algoritmos fuertes" vago → `AES-256-GCM / XChaCha20-Poly1305`, envelope + KMS/HSM.
- **OWASP 2021 como única referencia (gap crítico 2026)**: sin API Top 10 2023 (BOLA/IDOR ausente en todo el framework), sin LLM Top 10 2025 (prompt injection, insecure output, vector-store poisoning — grave porque DevFlow genera código que llama LLMs). Actualizar §8 o nuevo anexo.
- SSRF superficial (§4): añadir egress filtering, bloqueo `169.254.169.254`, allowlist DNS, anti-rebinding.
- CSRF §8: `SameSite=Lax` como defensa primaria es peligroso (top-level GET 2min, navegadores viejos). Exigir token synchronizer + `Origin/Referer` + Fetch Metadata en state-changing.
- Rate limiting sin lockout-vs-stuffing ni backoff con jitter cuantificado. Cuantificar.
- Logging de fallos sin sampling → inundación + GDPR. Añadir sampling + minimización.
- Contradicción interna: §6 declara `error-handling.md §5` canónico para stack-trace pero §11 mantiene BLOCK propio citando §6 → doble conteo. Retirar BLOCK de §11, dejar cita.

### 4.3 `clean-architecture.md` — rígido, capa-primero vs feature-primero

- "Inner layers must be deployment units" confunde dependencia fuente-tiempo con despliegue. Corregir: Dependency Rule es de código fuente.
- Use Case clase-con-método-único impuesto incluso a CRUD/function-stack → explosión ficheros; contradice KISS/YAGNI. Admitir función pura cuando no hay estado.
- "No atrapar salvo para traducir" tensiona `error-handling.md` §2-3. Armonizar.
- Validación solo-dominio excluyente contradice `security.md` §1 (validar en borde). **Correcto: ambas** (shape en adapter + invariante en entidad). Corregir §3.
- Carpeta por capa + "dentro de Application por feature" es híbrido incoherente; `project-design.md` §2 recomienda Feature-Based >10 features sin regla de decisión. Añadir tabla de decisión.
- BLOCK "entidad ORM desde API" absoluto → admitir excepción prototipo/admin/BFF con DTO idéntico documentado.

### 4.4 `rest-api.md` — bueno en RFC 9457, opinado en envelope/versionado

- Envelope `{data,meta,errors}` obligatorio en success rompe JSON:API/HAL/plain-body + caching. Hacerlo recomendado-no-obligatorio; citar RFC 7240 `Prefer: return=minimal`.
- Códigos: faltan `202` (async, necesario con eventos), `304`, `412` (If-Match §2), `415` en tabla (mencionado §8). Completar.
- Versionado: `/v1/` path como default sin trade-offs; "compatibilidad dentro de major" mezcla SemVer con URI. Añadir alternativas (header/evolution) y criterio.
- **Bug en el propio ejemplo**: `?sort=+createdAt` — `+` en query es espacio sin `%2B`. Corregir ejemplo.
- §6 no define `default/max page size` aunque Self-Check §16 lo exige. Especificar.
- Idempotencia §9 sin scope usuario/endpoint, fingerprint, atomicidad concurrente. Enlazar `concurrency.md`.
- Seguridad §8 sin BOLA/IDOR (#1 API Top 10 2023), IDs enumerables, headers `RateLimit-*`/`Retry-After`, OpenAPI 3.1 (JSON Schema 2020-12), webhooks. Añadir.

### 4.5 `testing.md` — fuerte en TDD, flojo en 2026

- Sin property-based (`fast-check/Hypothesis/proptest`), mutation testing, contract testing (Pact), snapshot pitfalls. Añadir §.
- "Mock en puerto, nunca concreto" absoluto → admitir seam concreto en legacy/stdlib/`Date.now`.
- "E2E solo nightly" obsoleto con envs efímeros. Relativizar.
- "Green que toca más ficheros = mal scope" confunde TDD con scope-lock. Retirar.
- Cobertura "happy+1 edge+1 failure" insuficiente en lógica crítica → boundary values + tablas decisión + branch vs line + mutation score.
- Falta: taxonomía doubles, flaky/async, builders, DB compartida en paralelo.

### 4.6 `performance.md` — medir-primero correcto, ingenuo en caché/DB

- "Hash O(1) sobre scan" ignora localidad CPU (n pequeño) y HashDoS. Matizar.
- "Eager/lazy flexible vía repositorio" filtra ORM al puerto, viola Clean Arch + causa N+1. **Sustituir por fetch-join/proyección**.
- Réplicas sin lag/stale/ruteo. Añadir.
- TTL sin thundering herd (`singleflight`, coalescing), negative caching, poisoning. Añadir.
- "Async/non-blocking para todo I/O" falso universal (goroutines, virtual threads Java 21, Django sync válidos). Corregir sesgo Node.

### 4.7 `logging.md` — excelente, 3 fricciones

- "Mask o hash PII" sin advertir que hash rápido = pseudónimo GDPR (necesita HMAC + llave + minimización). Añadir.
- "Nunca bodies/headers/query" absoluto mata diagnóstico → allowlist + redacción + sampling.
- Audit append-only sin WORM/hash-chain; sin conflicto retención vs olvido. Añadir.
- **Contradicción**: appenders async lossy (§7) vs audit lossless (§5). Doble canal explícito.
- Falta: log injection (CRLF), MDC en async, OpenTelemetry (estándar 2026), cardinalidad.

### 4.8 `error-handling.md` — de los mejores

- "Atrapar tipo más estrecho" asume `catch (Specific)` JVM/C#; en JS/TS es `catch (unknown)` + narrowing. Añadir rama.
- Ignorado-con-comentario frágil → API explícita (`void`, `catch (_ignored)`).
- Sin regla fail-fast vs Result/Optional (NotFound). Añadir tabla de decisión.
- Falta taxonomía retryable/fatal, códigos estables, localización, `panic`/`unwrap` hazards.

### 4.9 `concurrency.md` — muy fuerte, sesgo JVM

- Test real de concurrencia exigido (§2) excelente; falta cómo (hilos/iteraciones, determinismo `loom/shuffle`, flakiness CI). Añadir guía.
- "Toda lectura/escritura con mismo primitivo" ignora lock-free/volatile/RCU/actores. Matizar.
- Safe Publication en modelo Java; en JS/Go/Python difiere. Marcar por-runtime o admitir agnosticismo parcial.
- Idempotencia con BLOCK en 5 ficheros → triple conteo (ver C7).

### 4.10 `dependencies.md` — supply-chain sólido, 2 contradicciones

- "Rangos acotados + pin en lockfile" vs `security.md` §5 "pin versions". Distinguir apps (lockfile) vs librerías (rangos). Armonizar.
- "Critical/high = blocker" absoluto → fatiga con transitivas dev-only no alcanzables. Añadir alcanzabilidad/exploitabilidad (VEX, CVSS ambiental).
- Falta SBOM CycloneDX/SPDX (EU CRA 2024-27), verificación hash lockfile, defensas dependency-confusion, EOL policy.

### 4.11 `accessibility.md` — impecable técnico, cojo legal

- **Gap 2026**: sin European Accessibility Act (junio 2025), ADA, §508. Añadir anexo legal (blocker en UE).
- Falta WCAG 2.2 nuevo (2.4.11/2.4.12, 2.5.7, 3.2.6, 3.3.7, reflow 1.4.10). Completar.
- Contradicción 44×44 (ver C4).

### 4.12 `git-conventions.md` — incompleto supply-chain

- Tipos omiten `build/ci/style`; `perf` ambiguo. Completar + sintaxis `feat!:`.
- Falta commits firmados (GPG/SSH, SLSA 2026), DCO, política merge/squash/rebase, hooks enforcement.

### 4.13 `ui-design.md` (387L, el mayor) — exhaustivo, absolutos opinables

- Grid "múltiplos de 4,8,12,16" mezcla 4pt/8pt (12 no múltiplo de 8). Fijar base única.
- "Nunca `#000/#fff`" contradice high-contrast/OLED. Relativizar.
- "Overlay nunca inline" vs colocación React contextual. Relativizar.
- "Validar en blur, nunca por keystroke" obsoleto: mejor blur-primero + live después. Actualizar + "rehabilitar submit en error".
- Falta Core Web Vitals 2024+ (INP sustituye FID), budgets LCP/CLS, AVIF/srcset, `forced-colors`, `prefers-contrast`.

### 4.14 `project-design.md` — anti-sobreingeniería bueno, 2 patrones compiten

- Layered vs Hexagonal sin regla de decisión vs `clean-architecture.md`. Añadir tabla (tamaño/complejidad/fronteras).
- "Nunca `utils/helpers/common`" absoluto contradice DDD shared kernel. Prohibir dumping, no `common` per se.
- Sin modelado serverless/edge handlers. Añadir.

### 4.15 Transversales nuevos — alto nivel

`design-principles.md` (DRY-regla-de-tres, YAGNI, KISS) + `design-patterns.md` (tabla Problema→Patrón→Cuándo-no, composición>herencia, sin BLOCK por defecto §6) excelentes y frenan over-engineering. `data-persistence.md` (invariantes schema, reversibles multi-deploy, RLS, lógico vs físico) correcto. `event-driven-architecture.md` (at-least-once, idempotencia, DLQ, notification<carried-state<sourcing) muy actual — falta outbox pattern + schema registry. `integration-consumption.md` (timeouts, retry solo-idempotente, circuit-breaker) el mejor nuevo — falta hedging/retry budgets. `state-lifecycle.md` (single owner, derivada vs almacenada, superseded tags) cubre bugs que escapan a reviews.

### 4.16 `shared/` no-standards

- `rules.md` (410L): Three Zones + Critical Friend con evidencia sólidos. **Tensión no resuelta**: BLOCK seguridad fuera de Core vs "no editar Outside sin aprobación" vs "elevar WARNING antes de otro trabajo". Falta **break-glass explícito para vuln crítica** (editar + justificar post-hoc).
- `output-format.md` (49L): `Additional Recommendations` obligatoria incluso vacía → ruido. Hacerla condicional.
- `memory-conventions.md` (276L): sólido; "borrar session memory" vs auditabilidad (métricas/trazabilidad referencian borrados). Conservar índice de artefactos archivados post-borrado.
- `framework-memory.md` (221L): precedencia + privacy guard buenos. **Falta defensa memory poisoning**: `candidate` como hint desde store compartido puede inyectar instrucciones futuras. Añadir revisión de promoción + sanitización.
- `stack-detection.md` (159L): orden correcto; frágil en DB por strings, `npx jest` falla ESM, faltan Bun/Deno/uv/Tauri. Completar matriz.
- `traceability-matrix.md` + `metrics-template.md`: determinismo bien; matriz única explota en 100+ filas (muestreo por waves); "Test Pass = —" en standalone oculta calidad; promedios manuales derivan a stale (derivar de `devflow-ctl`).

### Contradicciones prioritarias (las 7 a resolver primero)

1. **C1**: OCP `switch→polimorfismo` WARN (`solid.md` §2/§8) vs YAGNI "no strategy sin 2º caso" (`design-patterns.md` §3, `design-principles.md` §2).
2. **C2**: Validación en borde (`security.md` §1) vs solo-dominio (`clean-architecture.md` §3).
3. **C3**: Layer-first (`clean-architecture.md` §4) vs Feature-based (`project-design.md` §2).
4. **C4**: 44×44 mínimo (`ui-design.md` §9) vs 24×24 + 44 recomendado (`accessibility.md` §7; `ui-design.md` §16 lo mapea bien pero §9 lo redacta obligatorio).
5. **C5**: Pin exacto (`security.md` §5) vs rango + lockfile (`dependencies.md` §2).
6. **C6**: Diagnóstico lossy (`logging.md` §7) vs audit lossless (`logging.md` §5).
7. **C7**: Idempotencia BLOCK en 5 ficheros (`concurrency` §5, `error-handling` §8, `integration` §3, `event-driven` §2, `rest-api` §9) → triple conteo. Dejar 1 canónico + citas sin severidad propia.

---

## 5. Patrones de diseño

**Estado:** `design-patterns.md` (100L) + `design-principles.md` (112L) son correctos y modernos (tabla Problema→Patrón→Cuándo-no, composición > herencia, YAGNI/DRY-regla-de-tres/KISS, sin BLOCK por defecto — acertado). Uso en el framework:

- ✅ **Bien usados**: Strategy/ports para testability (`testing.md` §3), Template Method en SKILLs (fases), Observer en traceability/metrics, Circuit Breaker + retry-jitter (`integration`, `error-handling` §8), DLQ + versionado aditivo (event-driven), fetch-join pendiente (ver §4.6 — el anti-patrón a corregir es exponer lazy).
- ❌ **Mal aplicados o en tensión**:
  1. OCP-vía-herencia impuesto donde `match` exhaustivo es superior (C1, §4.1).
  2. Class-per-Use-Case impuesto a CRUD funcional (§4.3).
  3. Eager/lazy como opción del repositorio — filtra estrategia ORM al puerto, causa N+1 (§4.6). Sustituir por proyección/fetch-join.
  4. Falta **Outbox pattern** (atomicidad DB+broker) en event-driven; falta **BFF** en security/auth (mezcla bearer/cookie §4.2).
  5. `shared/templates/` (6 plantillas: api-rest, cli-tool, fullstack, library-sdk, mobile-app, web-frontend) sin `desktop-app` ni `graphql` referenciados por `devflow-templates` (§3.8.5).
- **Decisión requerida**: tabla Layered vs Hexagonal vs Feature-based con criterios objetivos (nº features, fronteras de despliegue, equipo) en `project-design.md` §2 + referencia desde `clean-architecture.md` §4 (resuelve C3).

---

## 6. Seguridad (framework + estándares + permisos)

### 6.1 Instalación remota sin verificación (🔴 Alta)

- `uninstall.sh:230` (`bash <(curl -fsSL …)`), `install.ps1:10` + `uninstall.ps1:10-14` (`irm … | iex`), `install.sh:293-300` + `uninstall.sh:72-84` (`git clone --depth 1 "$DEVFLOW_REPO"` con override por env, sin pin commit/rama/hash/firma). Compromiso de red/host/typosquatting = RCE.
- **Fix**: publicar checksums + tag firmado; instalador verifica `git verify-tag` o SHA-256; documentar alternativa offline; nunca `curl|bash` como única vía en docs.

### 6.2 Allowlist por prefijo burlable (🔴 Alta — bypass de aprobación)

- Snippets aprueban `Bash(grep *)`, `/^grep\b/`, `grep *`: auto-aprueban `grep x; rm -rf y`, `grep x && curl … | sh`, `echo evil > ~/.bashrc`, `grep x $(rm -rf ~)`. Match sobre prefijo, no sobre redirecciones/encadenamientos.
- Agravante: Tier A incluye binarios con escritura (`sed -i`, `awk >f`, `find -exec`, `cp/mv/mkdir/touch`, `echo/printf`, `sort/uniq >`) bajo etiqueta "Search/read" (`permissions/README.md:26`, `vscode.json:9`, `opencode.json:30-52`, `claude-code.json:31-53`). Scope-lock (`devflow-ctl`) es la única defensa real, en otra capa.
- **Fix**: denegar `;`, `&&`, `||`, `$()`, backticks, `>`, `>>`, `|` a comandos no-shell en el matcher (o exigir `ask` ante metacaracteres); mover binarios con escritura a Tier B; test en `permissions.bats` con payloads adversariales.

### 6.3 Supply-chain en allow (🔴 Alta)

- `opencode.json:56-58` (`npx *`, `pnpm *`, `yarn *`), `claude-code.json:57-59`, `vscode.json:11-12`: permiten `npx <pkg>` (descarga+ejecuta), `python -m pip install` (casa con `python *` allow aunque `pip install*` sea ask), `pnpm/yarn add`, `make *` / `go build` / `cargo build` (ejecutan `build.rs`, `go:generate`). Contradice `permissions/README.md:39-42` ("New dependencies trigger review").
- Guardrail del validador (§9, `validate-framework.sh:271-273` FORBIDDEN) sin `npx`, `pnpm add`, `pip3 install`, `npm i`; `"kill "` no casa `killall *`.
- **Fix**: `npx --yes *` y `<mgr> add/install *` → ask/deny; `python *` allow con excepción `*pip*`; ampliar FORBIDDEN; test de veredicto para cada bypass.

### 6.4 `eval/bin/devflow-eval` sin sandbox (🟠 Media)

- L132 `setsid bash -c "$cmd"` ejecuta `checks.sh` del workspace con CWD = resultado; `npm start` no confiable = ejecución arbitraria. Log `/tmp/eval-serve-$PORT.log` predecible (colisión/symlink squatting).
- L296-315 `scorecard.json` vía `echo` sin escapar (comilla/backslash rompe JSON); L253-263 `weight` a `$(( ))` sin validación; L289-293 `IFS='|'` con descripciones con `|`.
- **Fix**: sandbox (usuario/namespaces o al menos `set -u`, tmp `mktemp -d`, `PORT` aleatorio + lock), construir JSON con `jq`/`python3 -c json`, validar `weight =~ ^[0-9]+$`.

### 6.5 Gaps OWASP/2026 en estándares (🟠 Media-Alta, detalle en §4.2/§4.4/§4.10)

Sin API Top 10 2023 (BOLA), sin LLM Top 10 2025, SSRF superficial, CSRF `Lax`-primario, sin passkeys, sin TLS 1.2+, sin SBOM/SLSA/provenance obligatorio, sin EAA legal. Ver fixes en §4 y plan §9.

### 6.6 Menores

`vscode.json:3` (`/devflow-ctl/`) sin anclar casa con subcadenas; `opencode.json:22-23` duplica `git status*`; backup permisos de una generación (`$file.devflow-backup`, `install.sh:262`); falta break-glass documentado (`rules.md`, §4.16) y defensa memory-poisoning (`framework-memory.md`, §4.16).

---

## 7. Comandos, scripts, prompts, editor-profiles, tests, eval

### 7.1 Scripts bash — errores verificados

| ID | Hallazgo | Evidencia (verificada) | Fix |
|---|---|---|---|
| I-1.1 | OS `linux-gnu*` excluye Alpine (`linux-musl*`), Android | `install.sh:23`, `uninstall.sh:29` (verificado) | `linux*` |
| I-1.2 | `INSTALLED_PROFILES` calculada y nunca usada (peso muerto) | `install.sh:305-329` vs `340-364` | Usarla para filtrar o eliminarla |
| I-1.3 | Sin modo no-interactivo; `read -rp` cuelga en CI/sin TTY | `install.sh:369`, `uninstall.sh:111` (verificado) | Flags `--editor/--yes/--non-interactive` + env |
| I-1.4 | `sed` rutas sin escapar (`&`, `\|`, `\` corrompen instalado/JSON); mapeos herramientas sí escapan pero con clase incompleta (falta `\|`) | `install.sh:160-165,185-186,199-200,266-268` | Función `sed_escape` única con `s/[&\|/\\]/\\&/g` para todo |
| I-1.5 | `git config --global core.excludesFile` sobrescribe sin backup/pregunta; uninstall no revierte; `>>` sin garantizar newline | `install.sh:546` (verificado) | Backup + pregunta + revert en uninstall + `printf '\n'` previo |
| I-1.6 | `rm -rf "$DEVFLOW_STORE"` sin `${VAR:?}` (con `HOME` vacío → `/.devflow`); el repo sí usa el patrón seguro en otros puntos | `install.sh:434` (verificado) vs `install.sh:295`, `uninstall.sh:218` | `${DEVFLOW_STORE:?}` |
| I-1.7 | Guardia `rm -rf` bloquea vacío/`/`/`//` pero no `$HOME`/`$USER_DIR` | `uninstall.sh:152-158` vs purge que sí bloquea `$HOME` (L215) | Bloquear `$HOME`, `$USER_DIR`, `$DEVFLOW_STORE` padre |
| I-1.8 | Triple copia `MEMORY_HOME` sincronizada solo por comentario, sin check del validador | `install.sh:396-404`, `uninstall.sh:204-212`, `devflow-ctl:_mem_home` | Nueva sección validador §21 o fuente única |
| I-1.9 | Validador no portable a macOS (plataforma soportada): `grep -oP`, `declare -A`, `mapfile`, `realpath` fallan en bash 3.2/BSD grep → falsos positivos en cascada | `validate-framework.sh:69,96,131,183,222,230,466,622` | Reescribir sin `-P` (usar `grep -E`/`sed`), sin asociativos o con fallback, `readlink -f`/python fallback |
| I-1.10 | Parsing versiones por `head -1` frágil ante futuro campo `version`; lockfile no verifica `packages[""].version` (v2/v3) | `validate-framework.sh:388,394`, `install.sh:440,524` | `jq`/python3 con fallback, o anclar a top-level + `packages[""]` |
| I-1.11 | Clases regex subcomandos excluyen dígitos/`_` e incluyen `\|` literal | `validate-framework.sh:222,230` | `[a-z0-9_-]` sin `\|` |
| I-1.12 | YAML awk destruye comillas (`gsub(/["']/,"")`) y `snippet` sin sanitizar `..`/`/` (path traversal en parser) | `validate-framework.sh:243,257-258,371`, `install.sh:243` | Preservar comillas (parse `"key": "value"`), validar `snippet =~ ^[A-Za-z0-9_.-]+\.json$` |
| I-1.13 | PS1 `Get-Command` sin `-All` (WSL primero = falso "not found"); `install.ps1:92` no reenvía `@args` como `uninstall.ps1:96` | `install.ps1:48-54,92`, `uninstall.ps1:52-58,96` | `-All` + skip WSL + reenvío simétrico |
| I-1.14 | `merge-settings.py`: `sys.argv[1]` sin guardia (traceback), `json.loads` sin capture, `is_rule_map` frágil, mutación con referencias compartidas | `merge-settings.py:30-33,61,65` | `argparse` + `try/except` con mensaje + `copy.deepcopy` |

### 7.2 Prompts (`.github/prompts/`, 19 ficheros)

- Paridad 19↔19 exacta con skills (verificado) y `{{SKILLS_DIR}}` sin typos hoy (40×). **Brecha**: validador §1/§2 solo parsea `<{{SKILLS_DIR}}/…>` en skills, no `` `{{SKILLS_DIR}}/…` `` en prompts (`devflow.prompt.md:33-35` y resto). Un typo futuro (`{{SKILL_DIR}}`) se instala literal sin fallar nada.
- Fix: extender §2 a backtick-refs en prompts + test.
- Frontmatter `agent: workspace` válido en Copilot, instalado verbatim en opencode/Claude (significado desconocido allí); layout `claude-code` (`prompts == skills == ~/.claude/commands`, `claude-code.yaml:66-68`) sin test de interpretación. Verificar runtime o normalizar frontmatter por perfil.

### 7.3 Editor-profiles (5 YAML + `permissions/`)

- `write_file` (Antigravity, `antigravity.yaml:55`) sin otra aparición en el repo → herramienta posiblemente inexistente. Verificar nombre real o corregir.
- Antigravity conserva 10 tools VS Code por identidad + `/memories` por ausencia de sección (comentario 61-65) sin fuente. Verificar capacidades reales.
- `generic.yaml` conserva `memory` para target headless probablemente sin ella. Condicionar.
- **Colisión `opencode`↔`generic`**: mismo `user_dir` (`$HOME/.agents`) con sustituciones incompatibles → instalaciones cruzadas se mezclan sin aviso. Fix: `user_dir` distintos o guarda con aviso + backup.
- Detección autofágica: `paths.base == $USER_DIR` + el instalador crea el árbol → "installed" siempre tras primera instalación aunque se borre el editor. Verificar contenido, no existencia del dir.
- VS Code sin ask/deny (solo allow, `vscode.yaml:70-73`) → Tier B/C no enforzados allí; el instalador no avisa (el README sí, L61). Avisar en install.
- `docs/ARCHITECTURE.md`: ~15 links `](.agents/…)` rotos (resuelven a `docs/.agents/…`; correcto `../.agents/…`, solo L282 lo usa) + 3 con `<{{SKILLS_DIR}}/…>` sin sustituir (L342,346,395). Corregir prefijos; validador §1/§2 no mira `docs/` → extender o excluir explícitamente.

### 7.4 Tests (`tests/`, 6 bats, 3764L)

- `install.bats` (67L): **sin cobertura de VS Code (editor por defecto)**; caso antigravity no distingue reemplazar de borrar; `mapped_tokens` reimplementa el awk frágil (ciego a su propio bug); side-effect gitignore sin aserción. Añadir los 4.
- `permissions.bats`: helper diverge en `$USER_DIR` (`install.sh:251-253`); emulador `opencode_verdict` no validado contra matcher real; `vscode.json` sin prueba semántica de regex Tier A/B. Validar emulador + tests de allow/deny por tier.
- `validate-framework.bats` (705L): §§1-8,10,11,13 sin tests (integridad `devflow-ctl`, versiones, paridad, matriz standalone solo por inspección). Añadir al menos smoke tests.
- `devflow-ctl.bats`: `config set branch` y SHAs sin validación ni test; `devflow-ctl` no ejecuta `git checkout` (cero ocurrencias — verificado impacto solo visual/confusión + interpolación en agentes). Validar formato rama/SHA + test.
- `devflow-eval.bats`: lista 8 IDs hardcodeada (doble fuente de verdad), timing `<10s` flaky en CI, `sleep 1` + `pgrep` con carrera, skips sin `jq`/`curl`/`pgrep`. Dinamizar lista, tolerancias, guards.
- `devflow-memory.bats`: concurrencia solo caso feliz (6 escritores); `cd` sin `pushd/popd`. Ampliar contención + aislamiento explícito.
- Faltante global: `jq` sin guardia (`devflow-eval.bats:59,61,157,159,161`).

### 7.5 Eval (`eval/`, harness + 8 golden tasks + baselines 4.10.0→4.16.1)

Sano y bien diseñado (outcome checks, process solo reportados). Mismos fixes que §6.4 (sandbox, JSON, weight, `IFS`) + dinamizar lista de tasks en tests. Nada que rediseñar.

---

## 8. Puntos ciegos del validador y causa raíz transversal

El validador pasa en verde (verificado exit 0) con los defectos arriba presentes. Clases invisibles al gate:

1. **(a)** Nada valida `.github/prompts` (§1/§2 solo skills) → typos futuros se instalan literal.
2. **(b)** Nada corre fuera de GNU/Linux bash-4+ (macOS soportado pero `grep -oP`/`declare -A`/`mapfile` abortan) → el gate no existe donde debe correr.
3. **(c)** Semántica real de editores (match permisos, nombres tools no-VSCode, layout `commands/`) asumida por declaración YAML sin sonda runtime.
4. **(d)** Lógica inter-fases (doble invoke, ownership contadores/branches, severidades cruzadas, gates divergentes) — ningún § la modela. Se propone **§21 Contratos de handoff**: (i) cada `iterate X` con un único escritor declarado; (ii) cada auto-invoke con guarda lifecycle/standalone; (iii) cada gate con verificación espejo en ambas puntas; (iv) severidades `sca`/traceability/scope idénticas en Reviewer y Finalizer.
5. **(e)** Deriva `MEMORY_HOME` triple-copia y versiones lockfile v2/v3 (I-1.8, I-1.10).
6. **(f)** `docs/` fuera de cobertura (links rotos ARCHITECTURE.md).

**Causa raíz transversal:** tres fuentes de verdad compiten (prosa SKILL ↔ `devflow-ctl` ↔ validador) sin jerarquía declarada. La nota "limit 3, not the 2 this used to say in prose" (`devflow-review:246`) es el síntoma. **Regla a promulgar**: `devflow-ctrl` es fuente para límites/formatos/estados; la prosa solo lo cita (`see devflow-ctl iterate_default_max`), nunca lo duplica con literales; el validador prohíbe literales de límites en prosa (`grep -rE "limit [0-9]+" skills/ → FAIL salvo cita).

---

## 9. Plan de corrección priorizado

### Ola 1 — Seguridad y pérdida de datos (hacer ya)

1. **P1.1** Unificar `sca` High/Critical = BLOCK en Reviewer + Finalizer; Finalizer STOP pre-borrado (`devflow-finalize:44`, `devflow-review:73`). [H29/H45]
2. **P1.2** Gate traceability 100% + backlog en Finalizer Step 2 pre-borrado; espejo en orquestador Step 9. [H42/H5]
3. **P1.3** Escritor único `implement_debug` (Debugger); orquestador/Implementer solo-lectura + test. [H4/H37]
4. **P1.4** `init --scope` en perf/migrate/contract (+ rama BLOCK, modos/CI, aggregate, write-back). [T5/T1/T3/T4]
5. **P1.5** Matcher permisos: denegar metacaracteres (`;|&$()><`) o exigir ask; Tier A sin escritura; ampliar FORBIDDEN (`npx`, `pnpm add`, `pip3 install`, `npm i`, `killall`); tests adversariales. [§6.2/§6.3]
6. **P1.6** Instalación verificada: tags firmados + SHA-256 + vía offline documentada. [§6.1]
7. **P1.7** `rm -rf` con `${VAR:?}` + bloqueo `$HOME`/`$USER_DIR`; `git config --global` con backup/pregunta/revert. [I-1.6/I-1.7/I-1.5]
8. **P1.8** Break-glass documentado en `rules.md` (vuln crítica fuera de Core) + sanitización memory-poisoning en `framework-memory.md`. [§4.16]

### Ola 2 — Handoffs del ciclo (siguiente release)

9. **P2.1** Guardas lifecycle/standalone en Architect→Planner e Implementer→Reviewer; corregir H1/H2/H8 (mensajes y ruteo); rollback Validation Gate; idempotencia archivado validación. [H13/H24/H1/H2/H8/H3/H6]
10. **P2.2** Ownership branch/checkpoint (orquestador crea, implementer commitea); modo standalone Implementer; `scope check` + traceability-update en Debugger; transición atómica F7↔F5; slug standalone; bypass CI en Brainstorm/Stack-Gate/Finalizer-confirms/escape-analysis. [H25/H26/H27/H38/H39/H40/H9/H18/H41]
11. **P2.3** Reviewer: contador rama Planner, sufijos `-rN`/`-dbgN`, limpiar nota deriva + grep `limit 2`, reescribir blind-pass, sustituir "Wave 12". [H31/H32/H33/H34/H35]
12. **P2.4** Planner: `traceability check` en gate orquestador Step 4; Phase 4 completa post-gate; default `rigor=standard`; fallback sin validation-report. [H19/H20/H21/H22]
13. **P2.5** Standalone: Complexity Gate en refactor; fix full-suite bug-fix; STOP/wait + evidencia en perf; gate 5 artefactos + CVE-metodología en reverse; conteo 11 + Debugger-demo en tutorial; Reviewer en Bootstrap-templates; merge/skip en contract; Critical Friend + memoria en docs. [§3]
14. **P2.6** Nueva §21 validador (handoff contracts) + regla "sin literales de límites en prosa". [§8]

### Ola 3 — Estándares 2026 + robustez (release siguiente)

15. **P3.1** Resolver C1–C7 (tabla §4.16) con dueños por estándar.
16. **P3.2** `security.md`: BFF/DPoP/`__Host-`/`aud-iss`/`kid-jku`, passkeys, pepper/HIBP, TLS 1.2+, AES-GCM/envelope, API Top 10 2023 (BOLA), LLM Top 10 2025, SSRF egress/`169.254.169.254`, CSRF token+Origin, rate-limit cuantificado, sampling logs. [§4.2]
17. **P3.3** `rest-api.md`: envelope opcional, 202/304/412/415, ejemplo `sort` corregido, page-size spec, idempotencia con atomicidad, BOLA/OpenAPI 3.1/webhooks. [§4.4]
18. **P3.4** Resto estándares (§4.1, §4.3, §4.5–§4.15) + Outbox + BFF + tabla Layered/Hexagonal/Feature + EAA legal + SBOM/SLSA + firmados git.
19. **P3.5** Scripts: `linux*`, modo no-interactivo, `sed_escape` única, YAML parser con comillas + `snippet` sanitizado, validador portable macOS, versiones con `jq`/python, regex `[a-z0-9_-]`, PS1 `-All`, `merge-settings.py` robusto. [I-1.1–I-1.14 salvo Ola 1]
20. **P3.6** Prompts bajo cobertura (§2 prompts), `ARCHITECTURE.md` links, `write_file`/capacidades Antigravity verificadas, colisión `user_dir`, tests (VS Code, `jq` guards, listas dinámicas, semántica tiers). [§7.2–§7.4]
21. **P3.7** Eval sandbox + JSON + weight + IFS. [§6.4]

Cada ítem con PR dedicado y `Refs:` según convención (`Refs: M00NN` para memoria). Tras cada ola: `npm run validate && npm test` + re-auditoría de la costura tocada.

---

## 10. Anexo — inventario verificado

- **Versión**: 4.16.1 en `package.json:3`, `package-lock.json:3`, `CHANGELOG.md ## [4.16.1]` (925L). Scripts: `validate`, `validate:fix`, `lint:sh(:all)`, `test` (`bats tests/`), `install`/`uninstall` bash.
- **Skills (19)**: orquestador `devflow/SKILL.md` 436L + `lifecycle.md` 126L + `stack-mode.md` 29L; brainstorm 64L; architect 193L + spec-template 126L + exploration-guide 103L; plan 172L + plan-template 160L + mockup-rules 35L + stack-planning 44L; implement 201L + tdd-procedure 62L + stack-flow 43L; review 259L + review-checklist 226L + correctness-guide 147L; debug 126L + debug-template 62L; finalize 151L + summary-template 72L; test-helper 56L; refactor 273L; bug-fix 266L; feature 273L; perf 155L; migrate 153L; contract 142L; docs 141L; templates 261L; tutorial 85L; reverse 244L. Total SKILL.md ~3751L.
- **`shared/`**: 24 `.md` (rules 410L, memory-conventions 276L, framework-memory 221L, standalone-execution 198L, …) + `bin/devflow-ctl` 2828L + `standards/` 21 ficheros (ui-design 387L el mayor; security 178L; testing 176L; solid 132L; …) + `templates/` 6 plantillas.
- **`.github/prompts/`**: 19 ficheros (~26-62L); `instructions/devflow-conventions.instructions.md` 381L; `workflows/ci.yml` 65L (dual-locale).
- **Editor-profiles**: vscode 85L, opencode 110L, claude-code 120L, antigravity 83L, generic 85L + `permissions/` (vscode 20L, claude-code 100L, opencode 95L, README 116L).
- **`docs/`**: ARCHITECTURE 491L + 8 análisis/planes + `devflow/{specs,plans,reviews,knowledge-base/tutorial}` con artefactos 2026-09-08.
- **`scripts/`**: validate-framework.sh 1072L (§§1-20), lint-shell.sh 81L, merge-settings.py 88L.
- **`tests/`**: 6 bats 3764L (devflow-ctl 1636L, eval 445L, memory 541L, install 67L, permissions 130L, validate 705L).
- **`eval/`**: README 225L + `bin/devflow-eval` 334L + 8 tasks (001–008) + baselines 4.10.0→4.16.1.
- **Raíz**: install.sh 564L, uninstall.sh 231L, install.ps1 95L, uninstall.ps1 99L, README 457L, CONTRIBUTING 154L.

---

*Fin del reporte. Metodología y evidencias arriba; fixes propuestos con archivo:línea para ejecución directa. Siguiente paso recomendado: abrir Ola 1 (P1.1–P1.8) como issues/PRs individuales.*
