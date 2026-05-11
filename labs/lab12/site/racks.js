import {
  bindSortArrows,
  encPathSegment,
  escapeAttr,
  escapeHtml,
  parseError,
  showToast,
} from "/static/common.js";

const PAGE_SIZE_MAX = 500;

const state = {
  skip: 0,
  limit: 50,
  sort: "id_rack",
  order: "asc",
  filterRoom: "",
};

function clampRackPageSize(raw) {
  let n = Math.floor(Number(String(raw).trim()));
  if (!Number.isFinite(n)) n = state.limit;
  return Math.min(PAGE_SIZE_MAX, Math.max(1, n));
}

function syncRacksPageSizeInput() {
  $("#racks-page-size").value = String(state.limit);
}

function $(sel) {
  return document.querySelector(sel);
}

async function loadRoomDropdowns() {
  const res = await fetch(
    "/rooms?skip=0&limit=200&sort=room_name&order=asc"
  );
  if (!res.ok) throw new Error(await parseError(res));
  const rooms = await res.json();
  const filter = $("#filter-room");
  const createRoom = $("#rack-create-room");
  const keepFilter = state.filterRoom;
  filter.innerHTML = '<option value="">Все помещения</option>';
  createRoom.innerHTML = "";
  rooms.forEach((r) => {
    const o1 = document.createElement("option");
    o1.value = r.room_name;
    o1.textContent = r.room_name;
    filter.appendChild(o1);
    const o2 = document.createElement("option");
    o2.value = r.room_name;
    o2.textContent = r.room_name;
    createRoom.appendChild(o2);
  });
  if (keepFilter) {
    filter.value = keepFilter;
    for (const o of createRoom.options) {
      if (o.value === keepFilter) {
        createRoom.value = keepFilter;
        break;
      }
    }
  }
}

function racksQueryUrl() {
  const params = new URLSearchParams({
    skip: String(state.skip),
    limit: String(state.limit),
    sort: state.sort,
    order: state.order,
  });
  if (state.filterRoom) params.set("room_name", state.filterRoom);
  return `/racks?${params.toString()}`;
}

async function loadRacks() {
  const res = await fetch(racksQueryUrl());
  if (!res.ok) throw new Error(await parseError(res));
  const rows = await res.json();
  const tbody = $("#racks-body");
  tbody.innerHTML = "";

  rows.forEach((r) => {
    const tr = document.createElement("tr");
    tr.innerHTML = `
      <td>${r.list_index}</td>
      <td>${escapeHtml(r.room_name)}</td>
      <td>${escapeHtml(r.rack_number)}</td>
      <td>${r.storage_slots}</td>
      <td>${r.max_load}</td>
      <td>${r.height}</td>
      <td>${r.width}</td>
      <td>${r.length}</td>
      <td class="cell-actions">
        <button type="button" class="btn small" data-action="edit-rack"
          data-room="${escapeAttr(r.room_name)}"
          data-num="${escapeAttr(r.rack_number)}">Изменить</button>
        <button type="button" class="btn small danger" data-action="del-rack"
          data-room="${escapeAttr(r.room_name)}"
          data-num="${escapeAttr(r.rack_number)}">Удалить</button>
      </td>`;
    tbody.appendChild(tr);
  });

  const start = state.skip + 1;
  const end = state.skip + rows.length;
  $("#racks-page-label").textContent =
    rows.length === 0
      ? "Нет записей на этой странице"
      : `Показано ${start}–${end} (размер страницы ${state.limit})`;

  $("#racks-prev").disabled = state.skip <= 0;
  $("#racks-next").disabled = rows.length < state.limit;

  syncRacksPageSizeInput();

  tbody.querySelectorAll("button[data-action]").forEach((btn) => {
    btn.addEventListener("click", onRackAction);
  });
}

function onRackAction(ev) {
  const btn = ev.currentTarget;
  const action = btn.dataset.action;
  const room = btn.dataset.room;
  const num = btn.dataset.num;
  if (action === "edit-rack") openRackEdit(room, num);
  if (action === "del-rack") deleteRack(room, num);
}

function openRackEdit(roomName, rackNumber) {
  const tbody = $("#racks-body");
  const row = [...tbody.querySelectorAll("tr")].find((tr) => {
    const cells = tr.querySelectorAll("td");
    return (
      cells[1] &&
      cells[2] &&
      cells[1].textContent === roomName &&
      cells[2].textContent === rackNumber
    );
  });
  if (!row) return;
  const cells = row.querySelectorAll("td");
  const form = document.getElementById("rack-edit");
  form.elements.namedItem("original_room_name").value = roomName;
  form.elements.namedItem("original_rack_number").value = rackNumber;
  form.elements.namedItem("rack_number").value = cells[2].textContent;
  form.elements.namedItem("storage_slots").value = cells[3].textContent;
  form.elements.namedItem("max_load").value = cells[4].textContent;
  form.elements.namedItem("height").value = cells[5].textContent;
  form.elements.namedItem("width").value = cells[6].textContent;
  form.elements.namedItem("length").value = cells[7].textContent;
  $("#rack-edit-context").textContent = `Помещение: «${roomName}» (перенос между помещениями здесь недоступен — создайте новую запись).`;
  const wrap = document.getElementById("rack-edit-wrap");
  wrap.open = true;
  wrap.scrollIntoView({ behavior: "smooth", block: "nearest" });
}

async function deleteRack(roomName, rackNumber) {
  if (!confirm(`Удалить стеллаж «${rackNumber}» в «${roomName}»?`)) return;
  const res = await fetch(
    `/rooms/${encPathSegment(roomName)}/racks/${encPathSegment(rackNumber)}`,
    { method: "DELETE" }
  );
  if (!res.ok) {
    showToast(await parseError(res), "error");
    return;
  }
  showToast("Стеллаж удалён", "ok");
  await loadRacks();
}

function applySort(field, order) {
  state.sort = field;
  state.order = order;
  state.skip = 0;
  loadRacks().catch((e) => showToast(e.message, "error"));
}

$("#filter-room").addEventListener("change", async () => {
  state.filterRoom = $("#filter-room").value;
  state.skip = 0;
  const cr = $("#rack-create-room");
  if (state.filterRoom) {
    for (const o of cr.options) {
      if (o.value === state.filterRoom) {
        cr.value = state.filterRoom;
        break;
      }
    }
  }
  try {
    await loadRacks();
  } catch (e) {
    showToast(e.message, "error");
  }
});

$("#btn-all-racks").addEventListener("click", async () => {
  state.filterRoom = "";
  state.skip = 0;
  $("#filter-room").value = "";
  try {
    await loadRoomDropdowns();
    await loadRacks();
    showToast("Показаны все стеллажи (постранично)", "ok");
  } catch (e) {
    showToast(e.message, "error");
  }
});

function applyRacksPageSizeFromInput() {
  const input = $("#racks-page-size");
  const next = clampRackPageSize(input.value);
  input.value = String(next);
  if (next === state.limit) return;
  state.limit = next;
  state.skip = 0;
  loadRacks().catch((e) => showToast(e.message, "error"));
}

$("#racks-page-size").addEventListener("change", () => {
  applyRacksPageSizeFromInput();
});

$("#racks-page-size").addEventListener("keydown", (e) => {
  if (e.key === "Enter") {
    e.preventDefault();
    e.currentTarget.blur();
  }
});

$("#rack-create").addEventListener("submit", async (e) => {
  e.preventDefault();
  const fd = new FormData(e.target);
  const roomName = String(fd.get("room_name")).trim();
  const body = {
    rack_number: String(fd.get("rack_number")).trim(),
    storage_slots: Number(fd.get("storage_slots")),
    max_load: Number(fd.get("max_load")),
    height: Number(fd.get("height")),
    width: Number(fd.get("width")),
    length: Number(fd.get("length")),
  };
  const res = await fetch(`/rooms/${encPathSegment(roomName)}/racks`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  if (!res.ok) {
    showToast(await parseError(res), "error");
    return;
  }
  e.target.reset();
  const crEl = $("#rack-create-room");
  for (const o of crEl.options) {
    if (o.value === roomName) {
      crEl.value = roomName;
      break;
    }
  }
  showToast("Стеллаж создан", "ok");
  state.skip = 0;
  await loadRacks();
});

$("#rack-edit").addEventListener("submit", async (e) => {
  e.preventDefault();
  const form = e.target;
  const roomName = String(form.elements.namedItem("original_room_name").value);
  const origNum = String(form.elements.namedItem("original_rack_number").value);
  const body = {
    rack_number: String(form.elements.namedItem("rack_number").value).trim(),
    storage_slots: Number(form.elements.namedItem("storage_slots").value),
    max_load: Number(form.elements.namedItem("max_load").value),
    height: Number(form.elements.namedItem("height").value),
    width: Number(form.elements.namedItem("width").value),
    length: Number(form.elements.namedItem("length").value),
  };
  const res = await fetch(
    `/rooms/${encPathSegment(roomName)}/racks/${encPathSegment(origNum)}`,
    {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    }
  );
  if (!res.ok) {
    showToast(await parseError(res), "error");
    return;
  }
  document.getElementById("rack-edit-wrap").open = false;
  showToast("Стеллаж обновлён", "ok");
  await loadRacks();
});

$("#rack-edit-cancel").addEventListener("click", () => {
  document.getElementById("rack-edit-wrap").open = false;
});

$("#racks-prev").addEventListener("click", async () => {
  state.skip = Math.max(0, state.skip - state.limit);
  try {
    await loadRacks();
  } catch (err) {
    showToast(err.message, "error");
  }
});

$("#racks-next").addEventListener("click", async () => {
  state.skip += state.limit;
  try {
    await loadRacks();
  } catch (err) {
    showToast(err.message, "error");
  }
});

bindSortArrows(document, applySort);

const params = new URLSearchParams(window.location.search);
const roomParam = params.get("room");
if (roomParam) state.filterRoom = roomParam;

loadRoomDropdowns()
  .then(async () => {
    if (roomParam) {
      const fr = $("#filter-room");
      if ([...fr.options].some((o) => o.value === roomParam)) fr.value = roomParam;
      const cr = $("#rack-create-room");
      if ([...cr.options].some((o) => o.value === roomParam)) cr.value = roomParam;
    }
    await loadRacks();
  })
  .catch((e) => showToast(e.message, "error"));
