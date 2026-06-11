import os
import random
import uuid
from datetime import datetime, timedelta
from supabase import create_client, Client

# ============================================================
# CONFIGURATION
# ============================================================
SUPABASE_URL = os.environ.get('SUPABASE_URL')
SUPABASE_KEY = os.environ.get('SUPABASE_SERVICE_KEY')

if not SUPABASE_URL or not SUPABASE_KEY:
    raise ValueError("Missing Supabase credentials")

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

DAILY_USERS = 15
PLANS = ['weekly', 'monthly', 'annual', 'lifetime']
PRICES = {'weekly': 3.99, 'monthly': 12.99, 'annual': 99.99, 'lifetime': 249.99}
REFERRAL_SOURCES = ['organic', 'google_ads', 'social_media', 'friend_referral', 'app_store', 'other']
COUNTRIES = ['US', 'GB', 'CA', 'AU', 'DE', 'FR', 'IN', 'BR', 'JP', 'MX']
DEVICES = ['android', 'ios', 'web', 'windows', 'macos']
NAMES = ['Emma', 'Liam', 'Sophia', 'Noah', 'Olivia', 'Mason', 'Isabella', 'Lucas', 'Ava', 'Ethan',
         'Mia', 'Logan', 'Amelia', 'Elijah', 'Harper', 'Oliver', 'Evelyn', 'James', 'Abigail', 'Benjamin']

def random_date(start: datetime, end: datetime) -> datetime:
    return start + timedelta(seconds=random.randint(0, int((end - start).total_seconds())))

def generate_user(i: int):
    user_id = str(uuid.uuid4())
    signup_date = random_date(datetime.now() - timedelta(days=180), datetime.now())
    
    supabase.table('users').insert({
        'user_id': user_id,
        'email': f'sim_{user_id[:8]}@example.com',
        'name': f"{random.choice(NAMES)} {random.choice(['Smith', 'Johnson', 'Williams', 'Brown', 'Jones'])}",
        'signup_date': signup_date.isoformat(),
        'country': random.choice(COUNTRIES),
        'referral_source': random.choice(REFERRAL_SOURCES),
        'device_type': random.choice(DEVICES),
        'data_source': 'simulated'
    }).execute()
    
    return user_id, signup_date

def generate_subscription(user_id: str, signup_date: datetime):
    plan = random.choice(PLANS)
    price = PRICES[plan]
    
    if plan == 'weekly':
        end_date = signup_date + timedelta(days=7)
    elif plan == 'monthly':
        end_date = signup_date + timedelta(days=30)
    elif plan == 'annual':
        end_date = signup_date + timedelta(days=365)
    else:
        end_date = signup_date + timedelta(days=36500)
    
    is_active = end_date > datetime.now()
    
    sub = supabase.table('subscriptions').insert({
        'user_id': user_id,
        'plan_type': plan,
        'start_date': signup_date.isoformat(),
        'end_date': end_date.isoformat(),
        'is_active': is_active,
        'data_source': 'simulated'
    }).execute()
    
    subscription_id = sub.data[0]['subscription_id']
    
    supabase.table('payments').insert({
        'user_id': user_id,
        'subscription_id': subscription_id,
        'amount': price,
        'payment_date': signup_date.isoformat(),
        'status': 'success',
        'data_source': 'simulated'
    }).execute()
    
    # Generate renewal payments for active subscriptions
    if is_active and plan != 'lifetime':
        months_active = min(6, (datetime.now() - signup_date).days // 30)
        for m in range(1, months_active + 1):
            payment_date = signup_date + timedelta(days=30 * m)
            if payment_date <= datetime.now():
                supabase.table('payments').insert({
                    'user_id': user_id,
                    'subscription_id': subscription_id,
                    'amount': price,
                    'payment_date': payment_date.isoformat(),
                    'status': 'success',
                    'data_source': 'simulated'
                }).execute()

def generate_churn():
    # Get active subscriptions older than 30 days
    active_subs = supabase.table('subscriptions')\
        .select('*')\
        .eq('is_active', True)\
        .lt('start_date', (datetime.now() - timedelta(days=30)).isoformat())\
        .execute()
    
    # Churn 8% of eligible active users
    churn_count = max(1, int(len(active_subs.data) * 0.08))
    
    for sub in random.sample(active_subs.data, min(churn_count, len(active_subs.data))):
        supabase.table('subscriptions')\
            .update({
                'is_active': False,
                'cancellation_date': datetime.now().isoformat(),
                'cancellation_reason': random.choice(['too_expensive', 'dont_use', 'technical_issue', 'other'])
            })\
            .eq('subscription_id', sub['subscription_id'])\
            .execute()
        print(f"  ⚠️ Churned: {sub['subscription_id'][:8]}")

def main():
    print(f"🚀 Starting daily data generation...")
    print(f"📊 Generating {DAILY_USERS} new users")
    
    for i in range(DAILY_USERS):
        user_id, signup_date = generate_user(i)
        generate_subscription(user_id, signup_date)
        if (i + 1) % 5 == 0:
            print(f"  ✅ Generated {i + 1}/{DAILY_USERS} users")
    
    print(f"🔄 Processing churn...")
    generate_churn()
    
    # Summary
    user_count = supabase.table('users').select('*', count='exact').execute().count
    sub_count = supabase.table('subscriptions').select('*', count='exact').execute().count
    payment_count = supabase.table('payments').select('*', count='exact').execute().count
    
    print(f"\n📊 Database Summary:")
    print(f"   Users: {user_count}")
    print(f"   Subscriptions: {sub_count}")
    print(f"   Payments: {payment_count}")
    print(f"\n✅ Daily data generation complete!")

if __name__ == "__main__":
    main()