-- Rental Booking System Tables for GearShare

-- Enum for rental status
CREATE TYPE rental_status AS ENUM ('requested', 'approved', 'pending', 'accepted', 'rejected', 'canceled_by_requester', 'running', 'completed', 'disputed');

-- Enum for payment status
CREATE TYPE payment_status_enum AS ENUM ('pending', 'processing', 'completed', 'processing_for_refund', 'refunded', 'canceled');

-- Rental/Booking table
CREATE TABLE IF NOT EXISTS rentals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  equipment_id UUID NOT NULL REFERENCES equipment(id) ON DELETE CASCADE,
  owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  requester_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Rental dates and duration
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  total_days INTEGER NOT NULL,
  
  -- Pricing information
  per_day_price DECIMAL(10, 2) NOT NULL,
  discount_percentage INTEGER DEFAULT 0,
  subtotal DECIMAL(10, 2) NOT NULL,
  discount_amount DECIMAL(10, 2) DEFAULT 0,
  total_amount DECIMAL(10, 2) NOT NULL,
  
  -- Status tracking
  rental_status rental_status DEFAULT 'requested',
  payment_status payment_status_enum DEFAULT 'pending',
  
  -- Timestamps for payment and confirmation
  payment_time TIMESTAMP WITH TIME ZONE,
  payment_method VARCHAR(50),
  transaction_id VARCHAR(255),
  
  -- Confirmation timestamps
  owner_gave_confirmation_at TIMESTAMP WITH TIME ZONE,
  requester_received_confirmation_at TIMESTAMP WITH TIME ZONE,
  
  -- Additional details
  notes TEXT,
  cancellation_reason TEXT,
  refund_amount DECIMAL(10, 2),
  refund_processed_at TIMESTAMP WITH TIME ZONE,
  
  -- System timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  completed_at TIMESTAMP WITH TIME ZONE
);

-- Rental activity log for tracking status changes
CREATE TABLE IF NOT EXISTS rental_activity_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rental_id UUID NOT NULL REFERENCES rentals(id) ON DELETE CASCADE,
  action VARCHAR(100) NOT NULL,
  actor_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  old_status VARCHAR(50),
  new_status VARCHAR(50),
  details TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Payment records table (for payment history and reconciliation)
CREATE TABLE IF NOT EXISTS rental_payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rental_id UUID NOT NULL REFERENCES rentals(id) ON DELETE CASCADE,
  requester_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  amount DECIMAL(10, 2) NOT NULL,
  payment_method VARCHAR(50),
  transaction_id VARCHAR(255),
  payment_status payment_status_enum DEFAULT 'pending',
  
  payment_time TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for faster queries
CREATE INDEX idx_rentals_equipment_id ON rentals(equipment_id);
CREATE INDEX idx_rentals_owner_id ON rentals(owner_id);
CREATE INDEX idx_rentals_requester_id ON rentals(requester_id);
CREATE INDEX idx_rentals_status ON rentals(rental_status);
CREATE INDEX idx_rentals_payment_status ON rentals(payment_status);
CREATE INDEX idx_rentals_start_date ON rentals(start_date);
CREATE INDEX idx_rentals_end_date ON rentals(end_date);
CREATE INDEX idx_rentals_created_at ON rentals(created_at);
CREATE INDEX idx_rental_activity_rental_id ON rental_activity_logs(rental_id);
CREATE INDEX idx_rental_activity_actor_id ON rental_activity_logs(actor_id);
CREATE INDEX idx_rental_payments_rental_id ON rental_payments(rental_id);
CREATE INDEX idx_rental_payments_requester_id ON rental_payments(requester_id);
CREATE INDEX idx_rental_payments_owner_id ON rental_payments(owner_id);

-- Enable Row Level Security
ALTER TABLE rentals ENABLE ROW LEVEL SECURITY;
ALTER TABLE rental_activity_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE rental_payments ENABLE ROW LEVEL SECURITY;

-- RLS Policies for rentals
-- Renters can view their rental requests (where they are the requester)
CREATE POLICY "Renters can view their rental requests" ON rentals
  FOR SELECT USING (requester_id = auth.uid());

-- Owners can view rental requests for their equipment (where they are the owner)
CREATE POLICY "Owners can view rental requests for their equipment" ON rentals
  FOR SELECT USING (owner_id = auth.uid());

-- Renters can create rental requests
CREATE POLICY "Renters can create rental requests" ON rentals
  FOR INSERT WITH CHECK (requester_id = auth.uid());

-- Renters can update their own rental requests (for cancellation)
CREATE POLICY "Renters can update their own rental requests" ON rentals
  FOR UPDATE USING (requester_id = auth.uid() AND rental_status NOT IN ('running', 'completed', 'rejected'));

-- Owners can update rental requests (to approve/reject/mark as given)
CREATE POLICY "Owners can update rental requests for their equipment" ON rentals
  FOR UPDATE USING (owner_id = auth.uid());

-- RLS Policies for rental_activity_logs
CREATE POLICY "Users can view rental activity for their rentals" ON rental_activity_logs
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM rentals 
      WHERE rentals.id = rental_activity_logs.rental_id 
      AND (rentals.requester_id = auth.uid() OR rentals.owner_id = auth.uid())
    )
  );

CREATE POLICY "System can insert rental activity logs" ON rental_activity_logs
  FOR INSERT WITH CHECK (true);

-- RLS Policies for rental_payments
CREATE POLICY "Users can view payment records for their rentals" ON rental_payments
  FOR SELECT USING (requester_id = auth.uid() OR owner_id = auth.uid());

CREATE POLICY "Renters can insert payment records" ON rental_payments
  FOR INSERT WITH CHECK (requester_id = auth.uid());

CREATE POLICY "Users can update payment records for their rentals" ON rental_payments
  FOR UPDATE USING (requester_id = auth.uid() OR owner_id = auth.uid());

-- Trigger to update updated_at timestamp on rentals
CREATE OR REPLACE FUNCTION update_rentals_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER rentals_update_timestamp
BEFORE UPDATE ON rentals
FOR EACH ROW
EXECUTE FUNCTION update_rentals_timestamp();

-- Trigger to update updated_at timestamp on rental_payments
CREATE OR REPLACE FUNCTION update_rental_payments_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER rental_payments_update_timestamp
BEFORE UPDATE ON rental_payments
FOR EACH ROW
EXECUTE FUNCTION update_rental_payments_timestamp();

-- Trigger to automatically update equipment status when rental is completed
CREATE OR REPLACE FUNCTION update_equipment_after_rental()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.rental_status = 'completed' THEN
    UPDATE equipment
    SET status = 'available'::equipment_status
    WHERE id = NEW.equipment_id;
  ELSIF NEW.rental_status = 'running' THEN
    UPDATE equipment
    SET status = 'unavailable'::equipment_status
    WHERE id = NEW.equipment_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER rental_update_equipment_status
AFTER UPDATE ON rentals
FOR EACH ROW
WHEN (OLD.rental_status IS DISTINCT FROM NEW.rental_status)
EXECUTE FUNCTION update_equipment_after_rental();
