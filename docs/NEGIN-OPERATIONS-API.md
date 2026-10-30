# مدل داده و قرارداد API پورتال نگین پیروزی

این سند قرارداد پیاده‌سازی برای جایگزینی ذخیره محلی مرورگر با Cloudflare Worker + D1 است. رابط کاربری فعلی برای حالت آزمایشی از localStorage استفاده می‌کند؛ هیچ‌یک از داده‌های محلی کاربر به سرور ارسال نمی‌شود.

## اصول معماری
- تمام رکوردهای عملیاتی باید building_id داشته باشند تا جداسازی داده بین برج‌ها تضمین شود.
- ارتباط واحد با اشخاص از جدول unit_relationships موجود استفاده کند؛ نقش مالک، مستأجر، ساکن و عضو خانواده نباید در یک فیلد متنی خلاصه شود.
- تمام عملیات حساس باید مجوز سمت سرور داشته باشند؛ مخفی‌کردن دکمه در مرورگر کنترل دسترسی محسوب نمی‌شود.
- تغییر وضعیت، تأیید فیش، حذف، صدور صورتحساب و بستن دوره مالی باید رویداد audit ثبت کند.
- مبلغ‌ها به عدد صحیح ریال یا تومان با واحد صریح در API ذخیره شوند؛ تبدیل واحد پول در لایه نمایش انجام شود.
- زمان‌ها در API به ISO-8601 UTC و تاریخ‌های تقویمی شمسی در UI نمایش داده شوند.
- پیوست‌ها در R2 یا فضای فایل خصوصی نگهداری شوند؛ D1 فقط storage_key، MIME، size، checksum و metadata را ذخیره کند.
- نظرسنجی رسمی و رأی‌گیری مجمع نیازمند احراز هویت، قواعد نصاب، جلوگیری از رأی تکراری، ثبت نمایندگی و گزارش قابل ممیزی است. UI فعلی صرفاً نظرخواهی/دمو است.

## نگاشت ماژول‌های پنل مدیریت به جدول‌ها
| ماژول | جداول اصلی |
|---|---|
| واحدها و ساکنان | units, people, memberships, unit_relationships |
| شارژ و صورتحساب | finance_periods, charge_rules, charge_invoices |
| صندوق و حسابداری | finance_accounts, finance_transactions, finance_transaction_lines |
| رسید پرداخت | payment_receipts, building_documents |
| بودجه | building_budgets, finance_accounts |
| میز خدمت | service_requests, service_request_updates |
| دارایی و تعمیرات | building_assets, maintenance_plans, maintenance_jobs |
| پیمانکار و قرارداد | building_vendors, building_contracts |
| کارکنان و حقوق | building_staff, payroll_entries |
| انبار | inventory_items, inventory_movements |
| پارکینگ و تردد | parking_spaces, vehicle_registrations, visitor_logs |
| مرسولات | parcel_logs |
| مشاعات و رزرو | facility_resources, facility_reservations |
| اطلاعیه | building_announcements |
| جلسات و مصوبات | building_meetings, meeting_resolutions |
| نظرسنجی | building_polls, poll_options, poll_votes |
| اسناد | building_documents |
| رخداد و انرژی | building_incidents, meter_readings |

## قرارداد پیشنهادی REST
همه مسیرها زیر /buildings/:buildingId و با نشست احراز هویت‌شده هستند:
- GET/POST /units, GET/PATCH /units/:unitId, GET/POST /units/:unitId/relationships
- GET/POST /finance/periods, GET/POST /finance/charge-rules, POST /finance/periods/:periodId/issue-invoices
- GET/POST /finance/transactions, GET/POST /finance/receipts, POST /finance/receipts/:receiptId/review
- GET/POST /finance/budgets, GET /finance/reports/ledger, GET /finance/reports/unit-balances
- GET/POST /service-requests, PATCH /service-requests/:requestId, POST /service-requests/:requestId/updates
- GET/POST /assets, GET/POST /maintenance/plans, GET/POST /maintenance/jobs
- GET/POST /vendors, GET/POST /contracts, GET/POST /staff, GET/POST /payroll
- GET/POST /inventory/items, POST /inventory/movements
- GET/POST /parking/spaces, GET/POST /vehicles, GET/POST /visitors, POST /visitors/:visitorId/checkout
- GET/POST /parcels, POST /parcels/:parcelId/deliver
- GET/POST /facilities/resources, GET/POST /facilities/reservations, POST /facilities/reservations/:id/review
- GET/POST /announcements, GET/POST /meetings, GET/POST /meetings/:id/resolutions
- GET/POST /polls, POST /polls/:id/votes, GET/POST /documents, GET/POST /incidents, GET/POST /meters/readings

## قواعد محاسباتی که باید در سرور پیاده شوند
1. فرمول شارژ نسخه‌دار باشد و با صدور صورتحساب، snapshot فرمول و پارامترهای واحد نگهداری شود.
2. سهم مالک و ساکن با payer_type و صورتحساب مستقل ثبت شود؛ هرگز فقط یک بدهی تجمیعی برای هر واحد نسازید.
3. سند حسابداری دوبل باید جمع بدهکار و بستانکار برابر داشته باشد؛ سند قطعی پس از ثبت نباید ویرایش مستقیم شود و اصلاح با سند معکوس انجام شود.
4. مانده صندوق از تراکنش‌های قطعی محاسبه شود؛ فیش در انتظار بررسی، دریافتی قطعی نیست.
5. رزرو مشاعات باید تداخل زمانی، ظرفیت، سقف رزرو و وضعیت پرداخت را در تراکنش سرور کنترل کند.
6. موجودی انبار از گردش ورود/خروج محاسبه شود، نه صرفاً ویرایش عدد موجودی.
7. تردد و تحویل مرسوله باید actor، زمان و واحد مقصد داشته باشند.
8. حقوق و دستمزد فقط برای نقش‌های مجاز قابل مشاهده باشد.
9. خروجی گزارش باید فیلترها، زمان تولید و کاربر درخواست‌کننده را ثبت کند.
10. تمام داده‌های فعلی localStorage فقط داده آزمایشی‌اند و نباید بدون بازبینی و نگاشت به شناسه‌های واقعی به D1 منتقل شوند.

## امکاناتی که نیازمند اتصال خارجی هستند
- پرداخت واقعی: درگاه مجاز، callback امضاشده و تطبیق تراکنش.
- پیامک/ایمیل/پیام‌رسان: ارائه‌دهنده، صف ارسال، retry و ثبت delivery status.
- QR مهمان و پلاک‌خوان: تولید توکن امضاشده، دستگاه و لاگ رویداد؛ QR نمایشی به‌تنهایی مجوز ورود نیست.
- کنترل آسانسور، درب، راه‌بند و حسگر: سخت‌افزار، شبکه امن و سرویس واسط.
- فایل‌ها: فضای خصوصی و لینک امضاشده با کنترل مجوز.
- رأی‌گیری رسمی: احراز هویت و قواعد قانونی مجمع.

## تکمیل دامنه عملیاتی
ماژول‌های تکمیلی نیز در رابط مدیریت پیش‌بینی شده‌اند:
- تطبیق گردش بانکی و صندوق: bank_reconciliations
- تحویل و تحول مدیریت: management_handovers
- شیفت و حضور کارکنان: staff_attendance
- مجوزهای اسباب‌کشی و بازسازی: unit_permits
- سجل تاریخی ساختمان: building_events
- ساختار چندبلوکی: building_blocks و پیوند units.block_id

پنل مدیریتی نسخه فعلی ۳۰ ماژول دارد. در حالت محلی، تغییر وضعیت، جست‌وجو، خروجی CSV، پشتیبان JSON و بازیابی پشتیبان در مرورگر انجام می‌شود. ماشین‌حساب شارژ پیش‌برآورد است و صدور قطعی صورتحساب باید در سرور با snapshot فرمول، گرد کردن و قواعد مصوب انجام شود.

## توسعه‌های پیشنهادی API برای تکمیل ماژول‌های افزوده
- GET/POST /finance/reconciliations
- GET/POST /management-handovers
- GET/POST /staff/attendance
- GET/POST /units/:unitId/permits و POST /permits/:id/review
- GET/POST /events
- GET/POST /blocks
