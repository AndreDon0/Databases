import {
  bindSortArrows,
  encPathSegment,
  escapeAttr,
  escapeHtml,
  parseError,
  showToast,
} from "/static/common.js";

const PAGE_SIZE_MAX = 200;

const state = {
  skip: 0,
  limit: 25,
  sort: "id_room",
  order: "asc",
};

function clampPageSize(raw) {
  let n = Math.floor(Number(String(raw).trim()));
  if (!Number.isFinite(n)) n = state.limit;
  return Math.min(PAGE_SIZE_MAX, Math.max(1, n));
}

function syncRoomsPageSizeInput() {
  $("#rooms-page-size").value = String(state.limit);
}

function $(sel) {
  return document.querySelector(sel);
}

async function loadRooms() {
  const res = await fetch(
    `/rooms?skip=${state.skip}&limit=${state.limit}&sort=${encodeURIComponent(state.sort)}&order=${state.order}`
  );
  if (!res.ok) throw new Error(await parseError(res));
  const rows = await res.json();
  const tbody = $("#rooms-body");
  tbody.innerHTML = "";

  rows.forEach((r) => {
    const tr = document.createElement("tr");
    tr.innerHTML = `
      <td>${r.list_index}</td>
      <td>${escapeHtml(r.room_name)}</td>
      <td>${r.capacity_volume}</td>
      <td>${r.temp_conditions}</td>
      <td>${r.humidity_conditions}</td>
      <td class="cell-actions">
        <a class="btn small primary btn-racks-nav" href="/warehouse/racks?room=${encodeURIComponent(r.room_name)}">Стеллажи</a>
        <button type="button" class="btn small" data-action="edit-room" data-name="${escapeAttr(r.room_name)}">Изменить</button>
        <button type="button" class="btn small danger" data-action="del-room" data-name="${escapeAttr(r.room_name)}">Удалить</button>
      </td>`;
    tbody.appendChild(tr);
  });

  const start = state.skip + 1;
  const end = state.skip + rows.length;
  $("#rooms-page-label").textContent =
    rows.length === 0
      ? "Нет записей на этой странице"
      : `Показано ${start}–${end} (размер страницы ${state.limit})`;

  $("#rooms-prev").disabled = state.skip <= 0;
  $("#rooms-next").disabled = rows.length < state.limit;

  syncRoomsPageSizeInput();

  tbody.querySelectorAll("button[data-action]").forEach((btn) => {
    btn.addEventListener("click", onRoomAction);
  });
}

function onRoomAction(ev) {
  const btn = ev.currentTarget;
  const action = btn.dataset.action;
  const name = btn.dataset.name;
  if (action === "edit-room") openRoomEdit(name);
  if (action === "del-room") deleteRoom(name);
}

function openRoomEdit(name) {
  const tbody = $("#rooms-body");
  const row = [...tbody.querySelectorAll("tr")].find((tr) => {
    const cells = tr.querySelectorAll("td");
    return cells[1] && cells[1].textContent === name;
  });
  if (!row) return;
  const cells = row.querySelectorAll("td");
  const form = document.getElementById("room-edit");
  form.elements.namedItem("original_name").value = name;
  form.elements.namedItem("room_name").value = cells[1].textContent;
  form.elements.namedItem("capacity_volume").value = cells[2].textContent;
  form.elements.namedItem("temp_conditions").value = cells[3].textContent;
  form.elements.namedItem("humidity_conditions").value = cells[4].textContent;
  const wrap = document.getElementById("room-edit-wrap");
  wrap.open = true;
  wrap.scrollIntoView({ behavior: "smooth", block: "nearest" });
}

async function deleteRoom(name) {
  if (!confirm(`Удалить помещение «${name}» и все связанные стеллажи?`)) return;
  const res = await fetch(`/rooms/${encPathSegment(name)}`, { method: "DELETE" });
  if (!res.ok) {
    showToast(await parseError(res), "error");
    return;
  }
  showToast("Помещение удалено", "ok");
  await loadRooms();
}

function applySort(field, order) {
  state.sort = field;
  state.order = order;
  state.skip = 0;
  loadRooms().catch((e) => showToast(e.message, "error"));
}

$("#room-create").addEventListener("submit", async (e) => {
  e.preventDefault();
  const fd = new FormData(e.target);
  const body = {
    room_name: String(fd.get("room_name")).trim(),
    capacity_volume: Number(fd.get("capacity_volume")),
    temp_conditions: Number(fd.get("temp_conditions")),
    humidity_conditions: Number(fd.get("humidity_conditions")),
  };
  const res = await fetch("/rooms", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  if (!res.ok) {
    showToast(await parseError(res), "error");
    return;
  }
  e.target.reset();
  showToast("Помещение создано", "ok");
  state.skip = 0;
  await loadRooms();
});

$("#room-edit").addEventListener("submit", async (e) => {
  e.preventDefault();
  const form = e.target;
  const orig = String(form.elements.namedItem("original_name").value);
  const body = {
    room_name: String(form.elements.namedItem("room_name").value).trim(),
    capacity_volume: Number(form.elements.namedItem("capacity_volume").value),
    temp_conditions: Number(form.elements.namedItem("temp_conditions").value),
    humidity_conditions: Number(form.elements.namedItem("humidity_conditions").value),
  };
  const res = await fetch(`/rooms/${encPathSegment(orig)}`, {
    method: "PATCH",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  if (!res.ok) {
    showToast(await parseError(res), "error");
    return;
  }
  document.getElementById("room-edit-wrap").open = false;
  showToast("Помещение обновлено", "ok");
  await loadRooms();
});

$("#room-edit-cancel").addEventListener("click", () => {
  document.getElementById("room-edit-wrap").open = false;
});

$("#rooms-prev").addEventListener("click", async () => {
  state.skip = Math.max(0, state.skip - state.limit);
  try {
    await loadRooms();
  } catch (err) {
    showToast(err.message, "error");
  }
});

$("#rooms-next").addEventListener("click", async () => {
  state.skip += state.limit;
  try {
    await loadRooms();
  } catch (err) {
    showToast(err.message, "error");
  }
});

function applyRoomsPageSizeFromInput() {
  const input = $("#rooms-page-size");
  const next = clampPageSize(input.value);
  input.value = String(next);
  if (next === state.limit) return;
  state.limit = next;
  state.skip = 0;
  loadRooms().catch((err) => showToast(err.message, "error"));
}

$("#rooms-page-size").addEventListener("change", () => {
  applyRoomsPageSizeFromInput();
});

$("#rooms-page-size").addEventListener("keydown", (e) => {
  if (e.key === "Enter") {
    e.preventDefault();
    e.currentTarget.blur();
  }
});

bindSortArrows(document, applySort);

loadRooms().catch((e) => showToast(e.message, "error"));
